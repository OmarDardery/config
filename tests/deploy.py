#!/usr/bin/env python3
"""Test deployment routing with fake commands; never activate the host."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
import json, os, pathlib, re, shutil, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
root = pathlib.Path(os.environ['TEST_ROOT'])
with (root/'events').open('a') as f: f.write(json.dumps([name, *args])+'\n')
if name == 'id': print(os.environ.get('TEST_UID','1000') if args == ['-u'] else 'tester')
elif name == 'uname': print('Linux' if args == ['-s'] else 'x86_64')
elif name == 'git':
    if args[0] == 'clone': shutil.copytree(root/'template', args[-1])
    elif 'get-url' in args: print(os.environ.get('TEST_ORIGIN','https://github.com/OmarDardery/config.git'))
elif name == 'nix':
    if 'eval' in args:
        if '--json' in args:
            if os.environ.get('TEST_CAPTURE_FAIL'): sys.exit(44)
            print(json.dumps({'stateVersion':'25.11', 'homeStateVersion':'25.05', 'bootLoader':{'grub': {'enable': True, 'device': '/dev/test'}}}))
        elif 'hardwareProfile' in ' '.join(args): print('generic')
        else: print('nixos')
    elif 'update' in args and os.environ.get('TEST_UPDATE_FAIL'): sys.exit(43)
    elif 'build' in args:
        if os.environ.get('TEST_BUILD_FAIL'): sys.exit(42)
elif name == 'sudo':
    if os.environ.get('TEST_SWITCH_FAIL'): sys.exit(4)
'''


class Deployment(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.home = self.base/'home with spaces'; self.home.mkdir()
        self.bin = self.base/'bin'; self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), TEST_ROOT=str(self.base),
                        PATH=f'{self.bin}:/usr/bin:/bin', XDG_STATE_HOME=str(self.base/'state'))
        self.template = self.base/'template'
        for name in ['.git','nixos','scripts']: (self.template/name).mkdir(parents=True)
        for name in ['flake.nix','flake.lock','nixos/profile.nix']: (self.template/name).write_text('{}')
        self.hardware = self.base/'hardware-configuration.nix'; self.hardware.write_text('{ fileSystems."/".device = "/dev/test"; }')
        helper = (ROOT/'scripts/copy-hardware.sh').read_text().replace('/etc/nixos/hardware-configuration.nix',str(self.hardware))
        (self.template/'scripts/copy-hardware.sh').write_text(helper)
        self.marker = self.base/'NIXOS'
        self.script = self.base/'apply.sh'
        self.script.write_text((ROOT/'scripts/apply.sh').read_text().replace('/etc/NIXOS',str(self.marker)))
        for name in ['id','uname','git','nix','sudo']:
            path=self.bin/name; path.write_text(f'#!{sys.executable}\n'+MOCK); path.chmod(0o755)
        self.repo=self.home/'config'

    def apply(self,*args,success=True):
        result=subprocess.run(['bash',str(self.script),*args],env=self.env,text=True,capture_output=True)
        if success: self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        else: self.assertNotEqual(result.returncode,0,result.stdout+result.stderr)
        return result

    def events(self,name=None):
        path=self.base/'events'
        entries=[json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
        return [entry for entry in entries if name is None or entry[0]==name]

    def builds(self): return [e for e in self.events('nix') if 'build' in e]

    def test_other_distros_rejected(self):
        self.assertIn('non-nixos', self.apply(success=False).stderr)
        self.assertFalse(self.events('git')); self.assertFalse(self.events('nix'))

    def test_nixos_uses_one_standard_rebuild_and_path_flake(self):
        self.marker.touch(); self.apply()
        self.assertEqual((self.repo/'nixos/hardware-configuration.nix').read_text(),self.hardware.read_text())
        self.assertEqual(self.events('sudo')[0][1:3],['nixos-rebuild','switch'])
        self.assertFalse(self.builds())
        self.assertIn(f'path:{self.repo}#nixos', self.events('sudo')[0])
        self.assertIn('--depth', self.events('git')[0])

    def test_build_failure_stops_activation(self):
        self.marker.touch(); self.env['TEST_BUILD_FAIL']='1'
        self.assertEqual(self.apply('--build-only',success=False).returncode,42)
        self.assertFalse(self.events('sudo'))

    def test_build_only(self):
        self.marker.touch()
        self.apply('--build-only')
        self.assertFalse(self.events('sudo'))
        self.assertIn('--no-link', self.builds()[0])

    def test_existing_checkout_and_hardware_preserved(self):
        shutil.copytree(self.template,self.repo)
        target=self.repo/'nixos/hardware-configuration.nix'; target.write_text('local edits')
        self.marker.touch(); self.apply()
        self.assertEqual(target.read_text(),'local edits')
        self.assertEqual(len(self.events('git')),1)
        self.assertIn('get-url',self.events('git')[0])

    def test_new_fork_revision(self):
        self.marker.touch()
        self.apply('github:someone/dotfiles','--ref','feature/portable')
        self.assertIn('https://github.com/someone/dotfiles.git',self.events('git')[0])
        self.assertEqual(self.events('git')[1][-2:],['checkout','feature/portable'])

    def test_existing_mismatch_or_ref_rejected(self):
        self.marker.touch()
        shutil.copytree(self.template,self.repo)
        self.apply('someone/other',success=False); self.apply('--ref','main',success=False)
        self.assertFalse(self.events('nix'))

    def test_invalid_input_and_root(self):
        for args in [('--wat',),('--repo-dir',),('--host','a.b'),('--home',),('--profile','dev'),('https://example.com/repo',)]:
            self.apply(*args,success=False)
        self.env['TEST_UID']='0'; self.apply(success=False)
        self.assertFalse(self.events('git'))

    def test_update_refreshes_inputs_then_uses_standard_rebuild(self):
        self.marker.touch(); self.apply('--update')
        calls=self.events('nix')
        update = next(c for c in calls if 'update' in c)
        self.assertIn('--flake',update)
        self.assertTrue(self.events('sudo'))
        self.assertFalse(self.builds())

    def test_update_failure_stops_build_and_switch(self):
        self.marker.touch(); self.env['TEST_UPDATE_FAIL']='1'
        self.assertEqual(self.apply('--update',success=False).returncode,43)
        self.assertFalse(self.builds()); self.assertFalse(self.events('sudo'))

    def test_switch_failure_is_reported(self):
        self.marker.touch(); self.env['TEST_SWITCH_FAIL']='1'
        self.assertEqual(self.apply(success=False).returncode,4)
        self.assertFalse(self.builds())

    def test_nix_interpolation_escaped(self):
        self.marker.touch()
        self.repo=self.home/'literal${dollar} and "quote"'
        self.apply('--repo-dir',str(self.repo))
        content=(self.repo/'nixos/local-profile.nix').read_text()
        self.assertIn(r'\${dollar}',content); self.assertIn(r'\"quote\"',content)

    def test_installed_bootloader_and_state_versions_preserved(self):
        self.marker.touch(); self.apply()
        saved = json.loads((self.repo/'nixos/local-system.json').read_text())
        self.assertEqual(saved['stateVersion'], '25.11')
        self.assertEqual(saved['homeStateVersion'], '25.05')
        self.assertTrue(saved['bootLoader']['grub']['enable'])
        self.apply()
        captures = [e for e in self.events('nix') if '--json' in e]
        self.assertEqual(len(captures), 1)

    def test_capture_failure_stops_activation(self):
        self.marker.touch(); self.env['TEST_CAPTURE_FAIL']='1'
        self.assertEqual(self.apply(success=False).returncode,44)
        self.assertFalse(self.events('sudo'))
        self.assertFalse((self.repo/'nixos/local-system.json').exists())

    def test_hardware_override(self):
        self.marker.touch(); self.apply('--hardware','asus-tuf-a14')
        self.assertIn('hardwareProfile = "asus-tuf-a14";', (self.repo/'nixos/local-profile.nix').read_text())

    def test_help_needs_no_privileges(self):
        self.env['TEST_UID']='0'
        self.assertIn('Home Manager',self.apply('--help').stdout)
        self.assertFalse(self.events())


if __name__=='__main__': unittest.main(verbosity=2)
