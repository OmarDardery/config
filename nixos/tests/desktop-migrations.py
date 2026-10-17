"""State safety, Kitty rollback, and updater confirmation in disposable directories."""
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "pkgs"))
import state_file

spec = importlib.util.spec_from_file_location("migration", ROOT / "pkgs/migrate-desktop.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def assert_no_scratch(self):
        self.assertFalse(list(self.root.rglob(".*.migration-*")))

    def test_kitty_fresh_migration_and_later_edits(self):
        target = self.root / "kitty/kitty.conf"
        defaults = ROOT / "dotfiles/kitty/kitty.conf"
        m.kitty(target, defaults)
        self.assertEqual(target.read_bytes(), defaults.read_bytes())
        original = b"font_size 23\ninclude ~/.local/state/noctalia/theme/kitty.conf\n"
        target.write_bytes(original)
        m.kitty(target, defaults)
        self.assertEqual(target.read_bytes(), b"font_size 23\ninclude themes/noctalia.conf\n")
        self.assertEqual(next(target.parent.glob("kitty.conf.backup-*")).read_bytes(), original)
        target.write_text("font_size 25\ninclude themes/noctalia.conf\n")
        m.kitty(target, defaults)
        self.assertIn("25", target.read_text())
        self.assertEqual(len(list(target.parent.glob("kitty.conf.backup-*"))), 1)

    def test_kitty_absolute_palette_include_and_custom_include(self):
        target = self.root / "kitty/kitty.conf"
        target.parent.mkdir()
        defaults = ROOT / "dotfiles/kitty/kitty.conf"
        palette = self.root / 'state "custom"/noctalia/theme/kitty.conf'
        original = f"font_size 23\ninclude {palette}\ninclude custom.conf\n".encode()
        target.write_bytes(original)
        m.kitty(target, defaults, palette)
        self.assertEqual(target.read_bytes(), b"font_size 23\ninclude themes/noctalia.conf\ninclude custom.conf\n")
        self.assertEqual(next(target.parent.glob("kitty.conf.backup-*")).read_bytes(), original)
        m.kitty(target, defaults, palette)
        self.assertEqual(len(list(target.parent.glob("kitty.conf.backup-*"))), 1)

    def test_noctalia_backup_marker_and_gui_choices(self):
        target = self.root / "settings.toml"
        marker = self.root / ".kitty-template-v1"
        original = b'# comment\n[other]\nvalue = 4\n[theme.templates]\nbuiltin_ids = ["gtk"]\n[theme.templates.user.kitty]\ninput_path = "old"\n'
        target.write_bytes(original)
        m.noctalia(target, marker)
        import tomlkit
        result = tomlkit.parse(target.read_text())
        self.assertEqual(result["other"]["value"], 4)
        self.assertEqual(result["theme"]["templates"]["builtin_ids"], ["gtk", "kitty"])
        self.assertNotIn("kitty", result["theme"]["templates"].get("user", {}))
        self.assertEqual(next(self.root.glob("settings.toml.backup-*")).read_bytes(), original)
        target.write_text('[theme.templates]\nbuiltin_ids = []\n')
        m.noctalia(target, marker)
        self.assertNotIn("kitty", target.read_text())

    def test_malformed_state_and_failed_replace_never_write_marker(self):
        target = self.root / "settings.toml"
        marker = self.root / ".kitty-template-v1"
        target.write_text("bad = [")
        with self.assertRaises(Exception):
            m.noctalia(target, marker)
        self.assertFalse(marker.exists())
        target.write_text('[theme.templates]\nbuiltin_ids = []\n')
        with patch.object(state_file.os, "replace", side_effect=OSError("replace failed")):
            with self.assertRaises(OSError):
                m.noctalia(target, marker)
        self.assertFalse(marker.exists())
        self.assert_no_scratch()

    def test_tablet_preserves_profiles_and_settings(self):
        target = self.root / "tablet.json"
        defaults = ROOT / "dotfiles/opentabletdriver/settings.json"
        m.tablet(target, defaults)
        current = json.loads(target.read_text())
        current["Extra"] = "preserve"
        current["Profiles"].append({"Tablet": "unrelated", "custom": 9})
        current["Profiles"][0]["Bindings"]["AuxButtons"] = []
        target.write_text(json.dumps(current))
        original = target.read_bytes()
        m.tablet(target, defaults)
        result = json.loads(target.read_text())
        self.assertEqual(result["Extra"], "preserve")
        self.assertEqual(result["Profiles"][1], current["Profiles"][1])
        bindings = result["Profiles"][0]["Bindings"]["AuxButtons"]
        self.assertEqual(bindings, json.loads(defaults.read_text())["Profiles"][0]["Bindings"]["AuxButtons"])
        self.assertIn("V", str(bindings))
        self.assertIn("F6", str(bindings))
        self.assertEqual(next(self.root.glob("tablet.json.backup-*")).read_bytes(), original)
        m.tablet(target, defaults)
        self.assertEqual(len(list(self.root.glob("tablet.json.backup-*"))), 1)

    def test_nonregular_and_symlink_files_rejected(self):
        real = self.root / "real"
        real.write_bytes(b"original")
        paths = []
        for name, destination in (("link", real), ("dangling", self.root / "missing")):
            path = self.root / name
            path.symlink_to(destination)
            paths.append(path)
        directory = self.root / "directory"
        directory.mkdir()
        fifo = self.root / "fifo"
        os.mkfifo(fifo)
        paths += [directory, fifo]
        for path in paths:
            with self.subTest(path=path.name):
                with self.assertRaises((OSError, ValueError)):
                    state_file.snapshot(path, missing_ok=True)
                with self.assertRaises((OSError, ValueError)):
                    state_file.replace(path, None, b"replacement")
                self.assertTrue(os.path.lexists(path))
        self.assertEqual(real.read_bytes(), b"original")
        self.assert_no_scratch()

    def test_concurrent_content_and_identity_changes(self):
        target = self.root / "settings"
        for same_content in (False, True):
            with self.subTest(same_content=same_content):
                target.write_bytes(b"original")
                original = state_file.snapshot(target)
                real_snapshot = state_file.snapshot

                def changed(path, **kwargs):
                    if same_content:
                        replacement = self.root / "new-inode"
                        replacement.write_bytes(b"original")
                        os.replace(replacement, target)
                    else:
                        target.write_bytes(b"GUI edit")
                    return real_snapshot(path, **kwargs)

                with patch.object(state_file, "snapshot", side_effect=changed):
                    with self.assertRaisesRegex(ValueError, "changed during"):
                        state_file.replace(target, original, b"migration")
                self.assertEqual(target.read_bytes(), b"original" if same_content else b"GUI edit")
                self.assert_no_scratch()
        for backup in self.root.glob("settings.backup-*"):
            self.assertEqual(backup.read_bytes(), b"original")
            self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o600)

    def test_backup_and_replacement_flush_and_cleanup(self):
        target = self.root / "settings"
        target.write_bytes(b"original")
        original = state_file.snapshot(target)
        with patch.object(state_file.os, "fsync", wraps=os.fsync) as sync:
            backup = state_file.replace(target, original, b"updated")
        self.assertGreaterEqual(sync.call_count, 4)
        self.assertEqual(backup.read_bytes(), b"original")
        for operation in ("replace", "fsync", "chmod"):
            target.write_bytes(b"original")
            with self.subTest(operation=operation), patch.object(state_file.os, operation, side_effect=OSError("injected")):
                with self.assertRaises(OSError):
                    state_file.replace(target, state_file.snapshot(target), b"updated", preserve_mode=True)
            self.assertEqual(target.read_bytes(), b"original")
            self.assert_no_scratch()

    def legacy_kitty(self):
        source = self.root / "legacy"
        source.mkdir()
        (source / "kitty.conf").write_bytes(b"font_size 31\n")
        (source / "conan.png").write_bytes(b"old asset")
        (source / "custom.conf").write_bytes(b"custom settings")
        (source / "kitty.conf").chmod(0o444)
        target = self.root / "kitty"
        target.symlink_to(source, target_is_directory=True)
        return source, target

    def test_directory_migration_preserves_all_existing_files(self):
        source, target = self.legacy_kitty()
        outside = self.root / "outside"
        outside.write_bytes(b"outside")
        outside.chmod(0o444)
        (source / "custom-link").symlink_to(outside)
        m.kitty_directory(target)
        self.assertFalse(target.is_symlink())
        self.assertEqual((target / "kitty.conf").read_bytes(), b"font_size 31\n")
        self.assertTrue((target / "kitty.conf").stat().st_mode & stat.S_IWUSR)
        self.assertEqual((target / "conan.png").read_bytes(), b"old asset")
        self.assertEqual((target / "custom.conf").read_bytes(), b"custom settings")
        self.assertTrue((target / "custom-link").is_symlink())
        self.assertEqual(stat.S_IMODE(outside.stat().st_mode), 0o444)
        backup = next(self.root.glob("kitty.backup-*"))
        self.assertEqual((backup / "kitty.conf").read_bytes(), (source / "kitty.conf").read_bytes())
        self.assertEqual((backup / "conan.png").read_bytes(), b"old asset")
        m.kitty_directory(target)
        self.assertEqual(len(list(self.root.glob("kitty.backup-*"))), 1)
        self.assert_no_scratch()

    def test_directory_failures_restore_link_and_clean_transaction(self):
        source, target = self.legacy_kitty()
        source.chmod(0o555)
        for operation in ("copytree", "chmod", "install"):
            with self.subTest(operation=operation):
                if operation == "copytree":
                    context = patch.object(m.shutil, "copytree", side_effect=OSError("copy failed"))
                elif operation == "chmod":
                    context = patch.object(m.os, "chmod", side_effect=OSError("chmod failed"))
                else:
                    rename = os.rename

                    def fail_install(src, dst):
                        if Path(src).name == "replacement":
                            raise OSError("install failed")
                        return rename(src, dst)

                    context = patch.object(m.os, "rename", side_effect=fail_install)
                with context, self.assertRaises(OSError):
                    m.kitty_directory(target)
                self.assertTrue(target.is_symlink())
                self.assertEqual(target.resolve(), source)
                self.assert_no_scratch()

    def test_failed_rollback_retains_recovery_link_and_backup(self):
        source, target = self.legacy_kitty()
        rename = os.rename

        def fail_commit_and_rollback(src, dst):
            if Path(src).name in ("replacement", "original-link"):
                raise OSError("injected failure")
            return rename(src, dst)

        with patch.object(m.os, "rename", side_effect=fail_commit_and_rollback):
            with self.assertRaises(OSError):
                m.kitty_directory(target)
        recovery = next(self.root.glob(".kitty.migration-*/original-link"))
        self.assertTrue(recovery.is_symlink())
        self.assertEqual(recovery.resolve(), source)
        backup = next(self.root.glob("kitty.backup-*"))
        self.assertEqual((backup / "kitty.conf").read_bytes(), b"font_size 31\n")
        os.rename(recovery, target)
        m.remove_transaction(recovery.parent)
        self.assert_no_scratch()

    def test_updater_confirmation_and_command_failures(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        log = self.root / "commands"
        for name in ("nix", "sudo"):
            script = bin_dir / name
            script.write_text('#!' + shutil.which("bash") + '\nprintf "%s\\n" "$*" >> "$LOG"\n[[ "$*" != *"$FAIL"* ]]\n')
            script.chmod(0o755)
        cases = [("yes\n", "never", True), ("no\n", "never", False), ("", "never", False),
                 ("yes\n", "flake update", False), ("yes\n", "build --no-link", False), ("yes\n", "nixos-rebuild", True)]
        for answer, failure, switches in cases:
            with self.subTest(answer=answer, failure=failure):
                log.write_text("")
                result = subprocess.run(["bash", str(ROOT / "pkgs/nixos-update.sh"), "/checkout with spaces", "host"], input=answer, text=True, capture_output=True,
                                        env={**os.environ, "PATH": str(bin_dir) + ":" + os.environ["PATH"], "LOG": str(log), "FAIL": failure, "XDG_CACHE_HOME": str(self.root / "cache")})
                self.assertEqual("nixos-rebuild switch" in log.read_text(), switches)
                self.assertEqual(result.returncode == 0, switches and failure == "never")
                commands = log.read_text().splitlines()
                self.assertEqual(commands[0], "flake update --flake path:/checkout with spaces")
                if failure != "flake update":
                    self.assertEqual(commands[1], "build --no-link path:/checkout with spaces#nixosConfigurations.host.config.system.build.toplevel")
                if switches:
                    self.assertEqual(commands[2], "nixos-rebuild switch --flake path:/checkout with spaces#host")
                if failure == "never":
                    self.assertIn("lockfile", result.stdout)
        log.write_text("")
        result = subprocess.run(["bash", str(ROOT / "pkgs/nixos-update.sh"), "path:/already prefixed", "host"], input="no\n", text=True, capture_output=True,
                                env={**os.environ, "PATH": str(bin_dir) + ":" + os.environ["PATH"], "LOG": str(log), "FAIL": "never", "XDG_CACHE_HOME": str(self.root / "cache")})
        self.assertEqual(result.returncode, 1)
        self.assertIn("--flake path:/already prefixed", log.read_text())
        self.assertNotIn("path:path:", log.read_text())

    def test_updater_invalid_arguments_and_concurrent_run(self):
        script = str(ROOT / "pkgs/nixos-update.sh")
        for arguments in ([], ["repo"], ["repo", "bad.name"], ["", "host"]):
            result = subprocess.run(["bash", script, *arguments], capture_output=True)
            self.assertEqual(result.returncode, 2)
        result = subprocess.run(["bash", script, "--help"], capture_output=True)
        self.assertEqual(result.returncode, 0)
        directory = self.root / "cache/nix-config"
        directory.mkdir(parents=True)
        with (directory / "update.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = subprocess.run(["bash", script, "repo", "host"], capture_output=True,
                                    env={**os.environ, "XDG_CACHE_HOME": str(self.root / "cache")})
            self.assertEqual(result.returncode, 1)
            self.assertIn(b"already running", result.stderr)


if __name__ == "__main__":
    unittest.main()
