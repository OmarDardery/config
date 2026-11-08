#!/usr/bin/env python3
"""Check native host prerequisites and synchronous Flatpak failure handling."""
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
if name == 'sudo' and os.environ.get('TEST_SUDO_FAIL'): sys.exit(41)
if name == 'sudo' and ('install' in args or '-S' in args):
    (root/'bin/flatpak').write_text('#!/bin/sh\nexit 0\n')
    (root/'bin/flatpak').chmod(0o755)
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

    def test_existing_flatpak_needs_no_sudo(self):
        self.command('flatpak')
        self.run_script('host-deps.sh')
        self.assertEqual(self.events(), [])

    def test_supported_package_managers(self):
        for manager in ['apt-get', 'dnf', 'pacman', 'zypper']:
            with self.subTest(manager=manager):
                self.command('sudo'); self.command(manager)
                self.run_script('host-deps.sh')
                events = self.events()
                self.assertTrue(any(e[0:2] == ['sudo', manager] and 'flatpak' in e for e in events))
                (self.bin/manager).unlink(); (self.bin/'flatpak').unlink()
                (self.root/'events').unlink()

    def test_host_package_failure_is_not_hidden(self):
        self.command('sudo'); self.command('apt-get')
        self.env['TEST_SUDO_FAIL'] = '1'
        result = self.run_script('host-deps.sh', success=False)
        self.assertEqual(result.returncode, 41)
        self.assertFalse((self.bin/'flatpak').exists())

    def test_missing_sudo_and_unsupported_manager_are_actionable(self):
        self.assertIn('distro administrator', self.run_script('host-deps.sh', success=False).stderr)
        self.command('sudo')
        self.assertIn('Unsupported host', self.run_script('host-deps.sh', success=False).stderr)
        self.assertEqual(self.events(), [])

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


class GraphicsSetup(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.link = self.root/'opengl-driver'
        self.conf = self.root/'non-nixos-gpu.conf'
        self.drivers = str(self.root/'drivers')
        self.setup = str(self.root/'package/bin/non-nixos-gpu-setup')
        self.script = self.root/'graphics.sh'
        self.script.write_text((ROOT/'non-nixos/graphics.sh').read_text()
                               .replace('/run/opengl-driver', str(self.link))
                               .replace('/etc/tmpfiles.d/non-nixos-gpu.conf', str(self.conf)))
        self.bin = self.root/'bin'; self.bin.mkdir()
        self.env = dict(os.environ, PATH=str(self.bin))
        (self.bin/'readlink').symlink_to('/usr/bin/readlink')

    def sudo(self, body):
        path = self.bin/'sudo'; path.write_text('#!/bin/bash\n'+body); path.chmod(0o755)

    def run_setup(self):
        return subprocess.run(['/bin/bash',str(self.script),self.drivers,self.setup],
                              env=self.env, capture_output=True, text=True)

    def test_current_driver_and_boot_config_need_no_sudo(self):
        self.link.symlink_to(self.drivers)
        self.conf.symlink_to(self.root/'package/lib/tmpfiles.d/non-nixos-gpu.conf')
        self.assertEqual(self.run_setup().returncode, 0)

    def test_missing_boot_config_requires_setup_even_with_matching_driver(self):
        self.link.symlink_to(self.drivers)
        self.assertIn('administrator', self.run_setup().stderr)

    def test_setup_failure_propagates(self):
        self.sudo('exit 41\n')
        self.assertEqual(self.run_setup().returncode, 41)

    def test_success_without_driver_link_is_rejected(self):
        self.sudo('exit 0\n')
        self.assertIn('did not create', self.run_setup().stderr)

    def test_setup_creates_driver_link_and_receives_exact_executable(self):
        self.sudo(f'[[ "$1" == -- && "$2" == "{self.setup}" ]] || exit 42\n'
                  f'/bin/ln -s "{self.drivers}" "{self.link}"\n')
        self.assertEqual(self.run_setup().returncode, 0)


if __name__ == '__main__': unittest.main(verbosity=2)
