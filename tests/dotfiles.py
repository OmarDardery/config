#!/usr/bin/env python3
"""Exercise standalone Home Manager bootstrap without changing the live home."""
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
import json, os, pathlib, shutil, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
root = pathlib.Path(os.environ['TEST_ROOT'])
with (root/'events').open('a') as stream: stream.write(json.dumps([name, *args])+'\n')
if name == 'id': print(os.environ.get('TEST_UID','1000') if args == ['-u'] else 'tester')
elif name == 'uname': print(os.environ.get('TEST_ARCH','x86_64'))
elif name == 'git':
    if args[0] == 'clone': shutil.copytree(root/'template', args[-1])
    elif 'get-url' in args: print(os.environ.get('TEST_ORIGIN','https://github.com/OmarDardery/config.git'))
elif name == 'nix':
    if 'update' in args and os.environ.get('TEST_UPDATE_FAIL'): sys.exit(43)
    if 'eval' in args:
        if os.environ.get('TEST_EVAL_FAIL'): sys.exit(45)
        if args[-1].endswith('.enable'): print('true')
        else: print('[]' if os.environ.get('TEST_ARCH') == 'aarch64' else '["com.valvesoftware.Steam"]')
elif name == 'flatpak': pass
elif name == 'home-manager' and os.environ.get('TEST_SWITCH_FAIL'): sys.exit(44)
'''


class StandaloneHome(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root/'home with spaces'; self.home.mkdir()
        self.bin = self.root/'bin'; self.bin.mkdir()
        self.template = self.root/'template'
        (self.template/'.git').mkdir(parents=True)
        shutil.copytree(ROOT/'non-nixos', self.template/'non-nixos',
                        ignore=shutil.ignore_patterns('local-profile.json'))
        (self.template/'non-nixos/host-deps.sh').write_text('#!/bin/bash\nprintf host-preflight >> "$TEST_ROOT/host-preflight"\n')
        self.marker = self.root/'NIXOS'
        self.script = self.root/'apply.sh'
        self.script.write_text((ROOT/'non-nixos/apply.sh').read_text().replace('/etc/NIXOS', str(self.marker)))
        self.env = dict(os.environ, HOME=str(self.home), TEST_ROOT=str(self.root),
                        PATH=f'{self.bin}:/usr/bin:/bin', XDG_STATE_HOME=str(self.root/'state'),
                        XDG_DATA_HOME=str(self.home/'custom data'), XDG_CONFIG_HOME=str(self.home/'custom config'), ZDOTDIR=str(self.home/'shell'))
        for name in ['id','uname','git','nix','home-manager','flatpak']:
            path = self.bin/name; path.write_text(f'#!{sys.executable}\n'+MOCK); path.chmod(0o755)
        self.repo = self.home/'config'

    def apply(self, *args, success=True):
        result = subprocess.run(['bash', str(self.script), *args], env=self.env, capture_output=True, text=True)
        if success: self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        else: self.assertNotEqual(result.returncode, 0)
        return result

    def events(self, name):
        p = self.root/'events'
        return [entry for line in p.read_text().splitlines() if (entry := json.loads(line))[0] == name] if p.exists() else []

    def test_switch_uses_standard_home_manager_and_unique_backups(self):
        self.apply()
        command = self.events('home-manager')[0]
        self.assertEqual(command[1], 'switch')
        self.assertIn(f'path:{self.repo}/non-nixos#tester', command)
        self.assertIn('--no-write-lock-file', command)
        self.assertTrue(command[command.index('-b')+1].startswith('before-home-manager-'))
        profile = json.loads((self.repo/'non-nixos/local-profile.json').read_text())
        self.assertEqual(profile['homeDirectory'], str(self.home))
        self.assertEqual(profile['configHome'], self.env['XDG_CONFIG_HOME'])
        self.assertEqual(profile['dataHome'], self.env['XDG_DATA_HOME'])
        self.assertEqual(profile['zshHome'], self.env['ZDOTDIR'])
        self.assertEqual(profile['system'], 'x86_64-linux')
        self.assertFalse((self.home/'custom config').exists())  # activation belongs to HM

    def test_reapply_preserves_identity_state_version_and_source_edits(self):
        self.apply()
        path = self.repo/'non-nixos/local-profile.json'
        profile = json.loads(path.read_text()); profile['stateVersion'] = '25.11'
        path.write_text(json.dumps(profile))
        source = self.repo/'non-nixos/home/default.nix'; source.write_text('# local edit')
        self.apply('--update')
        self.assertEqual(json.loads(path.read_text())['stateVersion'], '25.11')
        self.assertEqual(source.read_text(), '# local edit')
        self.assertFalse(any('pull' in call for call in self.events('git')))
        self.assertTrue(any('update' in call for call in self.events('nix')))

    def test_build_only_does_not_activate(self):
        self.apply('--build-only')
        self.assertFalse(self.events('home-manager'))
        self.assertFalse((self.root/'host-preflight').exists())
        self.assertIn('build', self.events('nix')[0])
        self.assertIn(f'path:{self.repo}/non-nixos#homeConfigurations.tester.activationPackage', self.events('nix')[0])

    def test_failed_update_and_activation_propagate(self):
        self.env['TEST_UPDATE_FAIL'] = '1'
        self.apply('--update', success=False)
        self.assertFalse(self.events('home-manager'))
        del self.env['TEST_UPDATE_FAIL']
        self.env['TEST_SWITCH_FAIL'] = '1'
        self.apply(success=False)

    def test_origin_mismatch_existing_ref_and_invalid_arguments_stop(self):
        self.apply()
        self.apply('someone/else', success=False)
        self.apply('--ref','another-branch', success=False)
        self.apply('--repo-dir', success=False)
        self.apply('--unknown', success=False)
        self.assertEqual(len(self.events('home-manager')), 1)

    def test_fork_ref_and_aarch64(self):
        self.env['TEST_ARCH'] = 'aarch64'
        self.apply('someone/config', '--ref','feature/native')
        self.assertIn('https://github.com/someone/config.git', self.events('git')[0])
        self.assertIn('checkout', self.events('git')[1])
        profile = json.loads((self.repo/'non-nixos/local-profile.json').read_text())
        self.assertEqual(profile['system'], 'aarch64-linux')
        self.assertFalse((self.root/'host-preflight').exists())

    def test_mismatched_identity_is_rejected(self):
        self.apply()
        path = self.repo/'non-nixos/local-profile.json'
        profile = json.loads(path.read_text()); profile['homeDirectory'] = '/home/someone-else'
        path.write_text(json.dumps(profile))
        self.apply(success=False)
        self.assertEqual(len(self.events('home-manager')), 1)

    def test_root_nixos_unsupported_arch_and_relative_xdg_rejected(self):
        self.env['TEST_UID'] = '0'; self.apply(success=False)
        self.env['TEST_UID'] = '1000'; self.marker.touch(); self.apply(success=False)
        self.marker.unlink(); self.env['TEST_ARCH'] = 'riscv64'; self.apply(success=False)
        self.env['TEST_ARCH'] = 'x86_64'; self.env['XDG_CONFIG_HOME'] = 'relative'; self.apply(success=False)
        self.assertFalse(self.events('home-manager'))

    def test_failed_config_evaluation_prevents_host_install_and_activation(self):
        self.env['TEST_EVAL_FAIL'] = '1'
        self.apply(success=False)
        self.assertFalse(self.events('home-manager'))
        self.assertFalse((self.root/'host-preflight').exists())

    def test_host_setup_failure_prevents_activation(self):
        (self.template/'non-nixos/host-deps.sh').write_text('#!/bin/bash\nexit 46\n')
        self.apply(success=False)
        self.assertFalse(self.events('home-manager'))

    def test_x86_runs_host_preflight_and_aarch_skips_empty_flatpak_list(self):
        self.apply()
        self.assertTrue((self.root/'host-preflight').exists())

    def test_help_needs_no_nix_or_home_manager(self):
        self.env['TEST_UID'] = '0'
        self.assertIn('Home Manager', self.apply('--help').stdout)
        self.assertFalse(self.events('home-manager'))

    def test_lock_blocks_second_apply(self):
        import fcntl
        state = Path(self.env['XDG_STATE_HOME'])/'non-nixos-config'; state.mkdir(parents=True)
        with (state/'apply.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertIn('another home apply', self.apply(success=False).stderr)


if __name__ == '__main__': unittest.main(verbosity=2)
