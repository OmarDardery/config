#!/usr/bin/env python3
"""Exercise migration, invalidation and installation boundaries without a GUI."""

import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "font_cache", Path(__file__).resolve().parents[1] / "pkgs/flatpak-font-cache.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class FontCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="font migration ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.fonts = self.root / "fonts-v1"
        self.fonts.mkdir()
        self.link = self.root / "current-fonts"
        self.link.symlink_to(self.fonts, target_is_directory=True)
        self.ref = "app/com.example.Notes/x86_64/stable"
        self.refs = {"user": [self.ref], "system": [self.ref]}
        self.commits = {"user": "old-user", "system": "old-system"}
        self.calls = []
        self.failing_scopes = set()
        environment = patch.dict(os.environ, {"XDG_STATE_HOME": str(self.root / "state")})
        environment.start()
        self.addCleanup(environment.stop)
        runner = patch.object(module.subprocess, "run", side_effect=self.run_flatpak)
        runner.start()
        self.addCleanup(runner.stop)

    def run_flatpak(self, args, **kwargs):
        self.calls.append(args)
        scope = "user" if "--user" in args else "system"
        if args[1] == "list":
            output = "\n".join(self.refs[scope])
        elif args[1] == "info":
            output = self.commits[scope]
        elif args[1] == "run":
            return subprocess.CompletedProcess(args, int(scope in self.failing_scopes))
        else:
            self.fail(f"Unexpected command: {args}")
        return subprocess.CompletedProcess(args, 0, stdout=output)

    def refresh(self):
        self.calls.clear()
        return module.refresh(self.link)

    def runs(self):
        return [args for args in self.calls if args[1] == "run"]

    def test_migrates_both_installations_then_skips_unchanged(self):
        self.assertEqual(self.refresh(), 0)
        self.assertEqual(len(self.runs()), 2)
        for args in self.runs():
            self.assertIn("--command=fc-cache", args)
            self.assertEqual(args[-2:], [self.ref, "-r"])
        self.assertEqual(self.refresh(), 0)
        self.assertEqual(self.runs(), [])

    def test_font_generation_change_refreshes_both(self):
        self.refresh()
        updated = self.root / "fonts-v2"
        updated.mkdir()
        self.link.unlink()
        self.link.symlink_to(updated, target_is_directory=True)
        self.assertEqual(self.refresh(), 0)
        self.assertEqual(len(self.runs()), 2)

    def test_application_update_refreshes_only_changed_installation(self):
        self.refresh()
        self.commits["system"] = "new-system"
        self.assertEqual(self.refresh(), 0)
        self.assertEqual(len(self.runs()), 1)
        self.assertIn("--system", self.runs()[0])

    def test_failure_is_retried_without_repeating_successful_refresh(self):
        self.failing_scopes.add("user")
        self.assertEqual(self.refresh(), 1)
        self.failing_scopes.clear()
        self.assertEqual(self.refresh(), 0)
        self.assertEqual(len(self.runs()), 1)
        self.assertIn("--user", self.runs()[0])

    def test_empty_installations(self):
        self.refs = {"user": [], "system": []}
        self.assertEqual(self.refresh(), 0)
        self.assertEqual(self.runs(), [])

    def test_missing_font_source_does_not_mark_success(self):
        self.link.unlink()
        with self.assertRaises(FileNotFoundError):
            self.refresh()
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
