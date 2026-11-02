#!/usr/bin/env python3
"""Exercise the native dotfile installer against disposable homes and Git stubs."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("dotfiles", ROOT / "non-nixos/apply.py")
dotfiles = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dotfiles)


class Dotfiles(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = self.root / "home with spaces/config"
        self.state = self.root / "state"
        self.state.mkdir()
        self.source = self.root / "source"
        shutil.copytree(ROOT / "non-nixos/dotfiles", self.source)

    def apply(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            dotfiles.install(self.source, self.config, self.state)
        return output.getvalue()

    def test_exact_scope_and_writable_copies(self):
        self.apply()
        expected = {p.relative_to(self.source) for p in self.source.rglob("*") if p.is_file()}
        actual = {p.relative_to(self.config) for p in self.config.rglob("*") if p.is_file()}
        self.assertEqual(expected, actual)
        self.assertEqual({p.parts[0] for p in actual}, {"nvim", "VSCodium", "umbriel", "noctalia"})
        self.assertFalse(any(p.is_symlink() for p in self.config.rglob("*")))
        self.assertFalse((self.root / "home with spaces/.bashrc").exists())

    def test_initial_conflicts_backed_up_and_unrelated_settings_preserved(self):
        user = self.config / "VSCodium/User"
        user.mkdir(parents=True)
        (user / "settings.json").write_text("previous settings")
        (user / "keybindings.json").write_text("my keybindings")
        self.apply()
        backups = list((self.state / "backups").rglob("settings.json"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "previous settings")
        self.assertEqual((user / "keybindings.json").read_text(), "my keybindings")

    def test_repeated_apply_no_changes_or_backups(self):
        self.apply()
        before = (self.config / "nvim/init.lua").stat().st_mtime_ns
        self.apply()
        self.assertEqual((self.config / "nvim/init.lua").stat().st_mtime_ns, before)
        self.assertFalse((self.state / "backups").exists())

    def test_updates_unedited_files_preserves_edits_and_deletions(self):
        self.apply()
        (self.config / "nvim/init.lua").write_text("-- my starter\n")
        (self.config / "VSCodium/User/settings.json").unlink()
        (self.source / "umbriel/config.toml").write_text("# updated source\n")
        result = self.apply()
        self.assertEqual((self.config / "nvim/init.lua").read_text(), "-- my starter\n")
        self.assertFalse((self.config / "VSCodium/User/settings.json").exists())
        self.assertEqual((self.config / "umbriel/config.toml").read_text(), "# updated source\n")
        self.assertIn("Keep local edit", result)
        self.assertIn("Keep local deletion", result)

    def test_old_home_manager_directory_and_file_links_materialized(self):
        store = self.root / "store"
        (store / "nvim/lua").mkdir(parents=True)
        (store / "nvim/init.lua").write_text("old init")
        (store / "nvim/lua/personal.lua").write_text("personal")
        (store / "codium.json").write_text("old codium")
        self.config.mkdir(parents=True)
        (self.config / "nvim").symlink_to(store / "nvim", target_is_directory=True)
        (self.config / "VSCodium/User").mkdir(parents=True)
        (self.config / "VSCodium/User/settings.json").symlink_to(store / "codium.json")
        self.apply()
        self.assertFalse((self.config / "nvim").is_symlink())
        self.assertFalse((self.config / "VSCodium/User/settings.json").is_symlink())
        self.assertEqual((self.config / "nvim/lua/personal.lua").read_text(), "personal")
        self.assertEqual((store / "nvim/init.lua").read_text(), "old init")
        self.assertEqual((store / "codium.json").read_text(), "old codium")

    def test_different_xdg_roots_are_independent(self):
        self.apply()
        self.config = self.root / "other xdg config"
        self.apply()
        self.assertTrue((self.config / "nvim/init.lua").is_file())

    def test_bad_source_rejected_before_dotfile_writes(self):
        (self.source / "unrequested").mkdir()
        (self.source / "unrequested/extra").write_text("bad")
        with self.assertRaises(ValueError): self.apply()
        self.assertFalse(self.config.exists())

    def run_main(self, *arguments, dirty=False, fail_pull=False):
        repo = self.root / "checkout"
        repo.mkdir(exist_ok=True)
        if not (repo / "non-nixos").exists():
            (repo / "non-nixos").mkdir()
            shutil.copytree(self.source, repo / "non-nixos/dotfiles")
        calls = []

        def git(directory, *args):
            calls.append(args)
            if args[0] == "remote": return "https://github.com/OmarDardery/config.git"
            if args[0] == "status": return " M non-nixos/dotfiles/nvim/init.lua" if dirty else ""
            if args[0] == "pull" and fail_pull: raise OSError("offline")
            return ""

        with patch.object(dotfiles.os, "getuid", return_value=1000), \
             patch.object(dotfiles, "git", side_effect=git), \
             patch.dict(os.environ, XDG_CONFIG_HOME=str(self.config), XDG_STATE_HOME=str(self.state)), \
             patch.object(dotfiles.sys, "argv", ["dotfiles-apply", "--repo-dir", str(repo), *arguments]), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            dotfiles.main()
        return calls

    def test_apply_never_pulls_or_invokes_an_app_manager(self):
        self.assertEqual(self.run_main(), [("remote", "get-url", "origin")])

    def test_update_fast_forwards_then_installs(self):
        self.assertIn(("pull", "--ff-only"), self.run_main("--update"))
        self.assertTrue((self.config / "noctalia/config.toml").exists())

    def test_dirty_or_failed_pull_stops_before_config_changes(self):
        with self.assertRaises(SystemExit): self.run_main("--update", dirty=True)
        self.assertFalse(self.config.exists())
        with self.assertRaises(OSError): self.run_main("--update", fail_pull=True)
        self.assertFalse(self.config.exists())

    def test_origin_mismatch_rejected(self):
        with self.assertRaises(SystemExit): self.run_main("someone/else")
        self.assertFalse(self.config.exists())

    def test_configs_are_valid_json_and_toml(self):
        import tomllib
        json.loads((self.source / "VSCodium/User/settings.json").read_text())
        for file in self.source.rglob("*.toml"):
            tomllib.loads(file.read_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
