#!/usr/bin/env python3
"""Check native Flatpak installation and failure handling."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
import json, os, pathlib, sys
root = pathlib.Path(os.environ['TEST_ROOT'])
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with (root/'events').open('a') as f: f.write(json.dumps([name, *args])+'\n')
if name == 'flatpak' and 'install' in args and os.environ.get('TEST_FAIL'): sys.exit(42)
'''


class NativeInstall(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root/'bin'; self.bin.mkdir()
        self.env = dict(os.environ, TEST_ROOT=str(self.root), HOME=str(self.root/'home'),
                        XDG_STATE_HOME=str(self.root/'state'), PATH=str(self.bin))

    def command(self, name):
        p = self.bin/name
        p.write_text(f'#!{sys.executable}\n'+STUB); p.chmod(0o755)

    def run_script(self, script, *args, success=True, full_path=False):
        env = dict(self.env)
        if full_path: env['PATH'] += ':/usr/bin:/bin'
        result = subprocess.run(['/bin/bash', str(ROOT/'non-nixos'/script), *args],
                                env=env, text=True, capture_output=True)
        if success: self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        else: self.assertNotEqual(result.returncode, 0)
        return result

    def events(self):
        p = self.root/'events'
        return [json.loads(line) for line in p.read_text().splitlines()] if p.exists() else []

    def test_user_installs_update_declared_apps_without_uninstalling(self):
        self.command('flatpak')
        self.run_script('flatpaks.sh', 'com.valvesoftware.Steam', 'com.vysp3r.ProtonPlus', full_path=True)
        events = self.events()
        self.assertTrue(all(e[1] == '--user' for e in events))
        self.assertEqual(sum('install' in e for e in events), 2)
        self.assertTrue(all('--or-update' in e for e in events if 'install' in e))
        self.assertFalse(any('uninstall' in e for e in events))

    def test_install_failure_is_not_hidden(self):
        self.command('flatpak'); self.env['TEST_FAIL'] = '1'
        result = self.run_script('flatpaks.sh', 'com.valvesoftware.Steam', full_path=True, success=False)
        self.assertEqual(result.returncode, 42)

    def test_invalid_ids_fail_before_remote_changes(self):
        self.command('flatpak')
        self.run_script('flatpaks.sh', 'invalid;name', full_path=True, success=False)
        self.assertEqual(self.events(), [])

    def test_empty_list_needs_no_flatpak(self):
        self.run_script('flatpaks.sh')
        self.assertEqual(self.events(), [])


if __name__ == '__main__': unittest.main(verbosity=2)
