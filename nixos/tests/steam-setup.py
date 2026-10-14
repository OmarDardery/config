"""Preview, ownership checks, and rollback using the packaged Steam hook targets."""
import importlib.util
import contextlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("steam_setup", ROOT / "pkgs/steam-setup.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
TARGETS = [Path(path) for path in json.loads(Path(sys.argv[1]).read_text())["targets"]]


class SteamSetupTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'steam "quoted"'
        self.root.mkdir()
        (self.root / "ubuntu12_32").mkdir()
        (self.root / "ubuntu12_32/steam").write_text("client")
        (self.root / "ubuntu12_64").mkdir()
        self.colors = Path(self.temp.name) / "steam.css"
        self.colors.write_text("body { color: red; }")
        self.destinations = [self.root / name for name in helper.DESTINATIONS]

    def apply(self, **kwargs):
        return helper.setup(self.root, self.colors, TARGETS, **kwargs)

    def links(self):
        return [os.readlink(path) if path.is_symlink() else None for path in self.destinations]

    def originals(self):
        for destination, pattern in zip(self.destinations, helper.MANAGED):
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.symlink_to(pattern.replace("*", "previous"))
        return self.links()

    def assert_no_transaction(self):
        self.assertFalse(list(self.root.glob(".noctalia-steam-setup-*")))

    def test_preview_changes_nothing_and_apply_is_repeatable(self):
        before = list(self.root.rglob("*"))
        self.apply()
        self.assertEqual(list(self.root.rglob("*")), before)
        self.apply(apply=True)
        self.assertEqual(self.links(), list(map(str, TARGETS)))
        before = [path.lstat() for path in self.destinations]
        self.apply(apply=True)
        self.assertEqual([path.lstat() for path in self.destinations], before)
        self.assert_no_transaction()

    def test_updates_recognized_dangling_links(self):
        self.originals()
        self.apply(apply=True)
        self.assertEqual(self.links(), list(map(str, TARGETS)))
        self.assert_no_transaction()

    def test_refuses_unmanaged_file_directory_and_symlink_without_changes(self):
        for kind in ("file", "directory", "symlink"):
            destination = self.destinations[0]
            if kind == "file":
                destination.write_text("user library")
            elif kind == "directory":
                destination.mkdir()
            else:
                destination.symlink_to("/user-owned/library")
            with self.subTest(kind=kind), self.assertRaisesRegex(ValueError, "unmanaged"):
                self.apply(apply=True)
            self.assertTrue(os.path.lexists(destination))
            if destination.is_dir() and not destination.is_symlink():
                destination.rmdir()
            else:
                destination.unlink()
            self.assert_no_transaction()

    def test_missing_client_palette_or_targets_changes_nothing(self):
        for name in ("client", "palette", "targets"):
            with self.subTest(name=name):
                if name == "client":
                    client = self.root / "ubuntu12_32/steam"
                    client.unlink()
                    args = (self.root, self.colors, TARGETS)
                elif name == "palette":
                    args = (self.root, self.root / "missing.css", TARGETS)
                else:
                    args = (self.root, self.colors, [self.root / "missing", *TARGETS[1:]])
                with self.assertRaises(ValueError):
                    helper.setup(*args, apply=True)
                if name == "client":
                    client.write_text("client")
                self.assertEqual(self.links(), [None, None, None])
                self.assert_no_transaction()

    def test_each_failed_link_restores_originals(self):
        for existing in (False, True):
            old = self.originals() if existing else [None, None, None]
            for failed_index in range(3):
                rename = os.rename

                def fail_install(source, destination):
                    if Path(source).name == f"new-{failed_index}":
                        raise OSError("injected installation failure")
                    return rename(source, destination)

                with self.subTest(existing=existing, index=failed_index), patch.object(helper.os, "rename", side_effect=fail_install):
                    with self.assertRaises(OSError):
                        self.apply(apply=True)
                self.assertEqual(self.links(), old)
                if not existing:
                    self.assertFalse((self.root / "millennium").exists())
                self.assert_no_transaction()

    def test_staging_and_permission_failures_leave_originals_intact(self):
        old = self.originals()
        for operation in ("stage", "park"):
            if operation == "stage":
                context = patch.object(Path, "symlink_to", side_effect=OSError("stage failed"))
            else:
                context = patch.object(helper.os, "rename", side_effect=PermissionError("park denied"))
            with self.subTest(operation=operation), context, self.assertRaises(OSError):
                self.apply(apply=True)
            self.assertEqual(self.links(), old)
            self.assert_no_transaction()

    def test_detects_intervening_change_and_restores_earlier_links(self):
        old = self.originals()
        snapshot = helper.snapshot
        reads = 0

        def changed(path):
            nonlocal reads
            if path == self.destinations[1]:
                reads += 1
                if reads == 2:
                    path.unlink()
                    path.symlink_to("/user-edited/library")
            return snapshot(path)

        with patch.object(helper, "snapshot", side_effect=changed), self.assertRaisesRegex(ValueError, "changed during"):
            self.apply(apply=True)
        self.assertEqual(self.links(), [old[0], "/user-edited/library", old[2]])
        self.assert_no_transaction()

    def test_preserves_foreign_link_replaced_during_installation(self):
        old = self.originals()
        rename = os.rename

        def intervening_edit(source, destination):
            rename(source, destination)
            if Path(source).name == "new-1":
                Path(destination).unlink()
                Path(destination).symlink_to("/user-intervening/library")

        with patch.object(helper.os, "rename", side_effect=intervening_edit), self.assertRaisesRegex(ValueError, "changed after"):
            self.apply(apply=True)
        self.assertEqual(self.links(), [old[0], "/user-intervening/library", old[2]])
        transaction = next(self.root.glob(".noctalia-steam-setup-*"))
        self.assertEqual(os.readlink(transaction / "old-1"), old[1])

    def test_rollback_failure_retains_recovery_links(self):
        old = self.originals()
        rename = os.rename

        def fail_install_and_rollback(source, destination):
            if Path(source).name in ("new-1", "old-0"):
                raise OSError("injected failure")
            return rename(source, destination)

        with patch.object(helper.os, "rename", side_effect=fail_install_and_rollback), self.assertRaises(OSError):
            self.apply(apply=True)
        transaction = next(self.root.glob(".noctalia-steam-setup-*"))
        self.assertEqual(os.readlink(transaction / "old-0"), old[0])
        self.assertEqual(os.readlink(self.destinations[1]), old[1])
        self.assertFalse(os.path.lexists(self.destinations[0]))
        os.rename(transaction / "old-0", self.destinations[0])


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
