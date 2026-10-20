#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import tomllib
import unittest
from unittest.mock import patch


HELPER = Path(__file__).resolve().parents[1] / "pkgs/reconcile-noctalia.py"
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "pkgs"))
spec = importlib.util.spec_from_file_location("reconcile_noctalia", HELPER)
import state_file

helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class ReconciliationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.state = self.root / "settings.toml"
        self.desired = self.root / "desired.toml"

    def files(self, state, desired):
        self.state.write_bytes(state.encode())
        self.desired.write_text(desired)
        return self.state.read_bytes()

    def run_helper(self, **kwargs):
        return helper.reconcile(self.state, self.desired, **kwargs)

    def test_preserve_changes_unknown_comments_and_version(self):
        self.files('# retained\nconfig_version = 3\nunknown = "private" # retained too\n'
                   '[bar]\nsize = 9\n[empty]\n',
                   'config_version = 3\n[bar]\nsize = 8\n')
        original = self.state.read_bytes()
        self.assertEqual(self.run_helper(apply=True), ([], None))
        self.assertEqual(self.state.read_bytes(), original)
        self.assertEqual(set(self.root.iterdir()), {self.state, self.desired})

    def test_nested_arrays_numbers_and_empty_cleanup(self):
        self.files('config_version = 3\n# Keep this comment\nunknown = "keep"\n'
                   '[empty]\n[a.b]\nx = 2.0\nitems = [{n = 1}, {n = 2}]\n'
                   '[changed]\nitems = [2, 1]\nflag = true\n',
                   'config_version = 3\n[a.b]\nx = 2\nitems = [{n = 1}, {n = 2}]\n'
                   '[changed]\nitems = [1, 2]\nflag = 1\n')
        removed, _ = self.run_helper(apply=True)
        self.assertEqual(removed, ['a.b.x', 'a.b.items'])
        self.assertEqual(tomllib.loads(self.state.read_text()), {
            'config_version': 3, 'unknown': 'keep', 'empty': {},
            'changed': {'items': [2, 1], 'flag': True}})
        self.assertIn('# Keep this comment', self.state.read_text())

    def test_explicit_resets_only_target_requested_fields(self):
        self.files('[plugins]\nenabled = ["old"]\nunknown = true\n'
                   '[bar.default]\nstart = ["old"]\nend = ["keep"]\n'
                   '[plugin_settings."avivbintangaringga/nix-monitor"]\n'
                   'update_command = "old"\nother = "keep"\n'
                   '[desktop_widgets.widget.desktop-widget-123]\n'
                   'output = "old"\nx = 4\n', '')
        resets = ['plugins.enabled', 'bar.default.start',
                  'plugin_settings.avivbintangaringga/nix-monitor.update_command',
                  'desktop_widgets.widget.desktop-widget-123.output']
        removed, _ = self.run_helper(apply=True, resets=resets)
        self.assertEqual(removed, resets)
        result = tomllib.loads(self.state.read_text())
        self.assertEqual(result['plugins'], {'unknown': True})
        self.assertEqual(result['bar']['default'], {'end': ['keep']})
        self.assertEqual(result['plugin_settings']['avivbintangaringga/nix-monitor'],
                         {'other': 'keep'})
        self.assertEqual(result['desktop_widgets']['widget']['desktop-widget-123'], {'x': 4})

    def test_fragmented_tables_booleans_and_arrays_of_tables(self):
        self.files('[a.b]\nx = 1\n[a]\nenabled = true\n[a.c]\nz = 3\n'
                   '[[items]]\nx = 1\n[[items]]\nx = 2\n',
                   '[a.b]\nx = 1\n[a]\nenabled = true\n[a.c]\nz = 4\n'
                   '[[items]]\nx = 1\n[[items]]\nx = 2\n')
        removed, _ = self.run_helper(apply=True)
        self.assertEqual(set(removed), {'a.b.x', 'a.enabled', 'items'})
        self.assertEqual(tomllib.loads(self.state.read_text()), {'a': {'c': {'z': 3}}})

    def test_managed_fields_win_but_runtime_state_and_unknown_fields_survive(self):
        original = self.files('config_version = 3\n[bar.default]\nstart = ["old"]\n'
                              'unknown = true\n[theme]\nmode = "light"\nsource = "builtin"\n'
                              '[wallpaper.last]\npath = "current.png"\n',
                              '[bar.default]\nstart = ["clock"]\n[theme]\nsource = "wallpaper"\n')
        removed, backup = self.run_helper(apply=True, managed=True)
        self.assertEqual(removed, ['bar.default.start', 'theme.source'])
        self.assertEqual(backup.read_bytes(), original)
        self.assertEqual(tomllib.loads(self.state.read_text()), {
            'config_version': 3, 'bar': {'default': {'unknown': True}},
            'theme': {'mode': 'light'}, 'wallpaper': {'last': {'path': 'current.png'}}})
        self.assertEqual(self.run_helper(apply=True, managed=True), ([], None))

    def test_managed_plugin_sources_replace_gui_overrides_without_losing_state(self):
        original = self.files(
            '[theme]\nmode = "light"\n[plugins]\nenabled = ["old/plugin"]\n'
            '[[plugins.source]]\nname = "old-local"\nkind = "path"\nlocation = "/old"\n',
            '[plugins]\nenabled = ["alexander/screen-toolkit"]\n'
            '[[plugins.source]]\nname = "nix-managed"\nkind = "path"\n'
            'location = "/nix/store/fixture-plugins"\nenabled = true\n',
        )
        removed, backup = self.run_helper(apply=True, managed=True)
        self.assertEqual(set(removed), {'plugins.enabled', 'plugins.source'})
        self.assertEqual(backup.read_bytes(), original)
        self.assertEqual(tomllib.loads(self.state.read_text()), {'theme': {'mode': 'light'}})

    def test_version_cannot_be_reset(self):
        original = self.files('config_version = 3\n', 'config_version = 3\n')
        self.assertEqual(self.run_helper(apply=True, resets=['config_version']), ([], None))
        self.assertEqual(self.state.read_bytes(), original)

    def test_wallpaper_and_algorithm_choices_survive_rebuilds(self):
        self.files('[theme]\nwallpaper_scheme = "vibrant"\nmode = "light"\n'
                   '[wallpaper.default]\npath = "/home/user/personal image.png"\n',
                   '[theme]\nsource = "wallpaper"\n[wallpaper]\ntransition_on_startup = true\n')
        original = self.state.read_bytes()
        for _ in range(2):
            self.assertEqual(self.run_helper(apply=True, managed=True), ([], None))
            self.assertEqual(self.state.read_bytes(), original)

    def test_dry_run_creates_nothing(self):
        original = self.files('[a]\nx = 1\n', '[a]\nx = 1\n')
        before = self.state.stat()
        self.assertEqual(self.run_helper(), (['a.x'], None))
        self.assertEqual(self.state.read_bytes(), original)
        self.assertEqual(self.state.stat(), before)
        self.assertEqual(set(self.root.iterdir()), {self.state, self.desired})

    def test_backup_exact_and_private_and_empty_state_retained(self):
        original = self.files('# original\r\nx = 1\r\n', 'x = 1\n')
        self.state.chmod(0o644)
        removed, backup = self.run_helper(apply=True)
        self.assertEqual(removed, ['x'])
        self.assertEqual(backup.read_bytes(), original)
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(self.state.stat().st_mode), 0o600)
        self.assertEqual(tomllib.loads(self.state.read_text()), {})
        self.assertTrue(self.state.is_file())

    def test_malformed_inputs_fail_without_writes(self):
        for state, desired in [('x = [', 'x = 1'), ('x = 1', 'x = [')]:
            with self.subTest(state=state, desired=desired):
                original = self.files(state, desired)
                with self.assertRaises(Exception):
                    self.run_helper(apply=True)
                self.assertEqual(self.state.read_bytes(), original)
                self.assertEqual(set(self.root.iterdir()), {self.state, self.desired})

    def test_nonregular_and_symlink_state_rejected(self):
        self.desired.write_text('x = 1\n')
        target = self.root / 'target.toml'
        target.write_text('x = 1\n')
        self.state.symlink_to(target)
        with self.assertRaises(OSError):
            self.run_helper(apply=True)
        self.assertEqual(target.read_text(), 'x = 1\n')
        self.state.unlink()
        self.state.mkdir()
        with self.assertRaises(ValueError):
            self.run_helper(apply=True)

    def test_changed_source_aborts_and_keeps_backup(self):
        original = self.files('x = 1\n', 'x = 1\n')
        snapshot = state_file.snapshot

        def changed(path, **kwargs):
            self.state.write_text('x = 2\n')
            return snapshot(path, **kwargs)

        with patch.object(state_file, 'snapshot', side_effect=changed):
            with self.assertRaisesRegex(ValueError, 'changed during'):
                self.run_helper(apply=True)
        self.assertEqual(self.state.read_text(), 'x = 2\n')
        backups = list(self.root.glob('settings.toml.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original)
        self.assertFalse(list(self.root.glob('.settings.toml.*')))

    def test_replace_failure_keeps_original_and_backup(self):
        original = self.files('x = 1\n', 'x = 1\n')
        with patch.object(state_file.os, 'replace', side_effect=OSError('failed')):
            with self.assertRaises(OSError):
                self.run_helper(apply=True)
        self.assertEqual(self.state.read_bytes(), original)
        self.assertEqual(next(self.root.glob('settings.toml.backup-*')).read_bytes(), original)
        self.assertFalse(list(self.root.glob('.settings.toml.*')))

    def test_cli_defaults_to_dry_run_and_does_not_print_values(self):
        original = self.files('secret = "private value"\n', '')
        result = subprocess.run([sys.executable, str(HELPER), str(self.state),
                                 str(self.desired), '--reset', 'secret'],
                                capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout, 'Would remove keys:\nsecret\n')
        self.assertEqual(self.state.read_bytes(), original)


if __name__ == '__main__':
    unittest.main()
