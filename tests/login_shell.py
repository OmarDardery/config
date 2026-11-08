#!/usr/bin/env python3
"""Exercise shell registration without editing system account files."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
import json, os, pathlib, subprocess, sys
root = pathlib.Path(os.environ['TEST_ROOT'])
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
if name == 'id': print(os.environ.get('TEST_UID','1000') if args == ['-u'] else 'tester')
elif name == 'getent': print('tester:x:1000:1000::/home/tester:' + os.environ.get('TEST_CURRENT','/bin/bash'))
elif name == 'sudo':
    if os.environ.get('TEST_SUDO_FAIL'): sys.exit(41)
    env = dict(os.environ, TEST_UID='0')
    sys.exit(subprocess.run(args[1:], env=env).returncode)
elif name == 'usermod':
    with (root/'events').open('a') as stream: stream.write(json.dumps(args)+'\n')
    if os.environ.get('TEST_USERMOD_FAIL'): sys.exit(42)
'''

class LoginShell(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root/'bin'; self.bin.mkdir()
        self.shell = self.bin/'zsh'; self.shell.write_text('#!/bin/sh\n'); self.shell.chmod(0o755)
        self.shells = self.root/'shells'; self.shells.write_text('/bin/bash')
        self.script = self.root/'login-shell.sh'
        self.script.write_text((ROOT/'non-nixos/login-shell.sh').read_text().replace('/etc/shells', str(self.shells)))
        self.env = dict(os.environ, TEST_ROOT=str(self.root), PATH=f'{self.bin}:/usr/bin:/bin')
        for name in ['id','getent','sudo','usermod']:
            p = self.bin/name; p.write_text(f'#!{sys.executable}\n'+STUB); p.chmod(0o755)

    def apply(self, username='tester', shell=None):
        return subprocess.run(['/bin/bash',str(self.script),username,str(shell or self.shell)],
                              env=self.env, text=True, capture_output=True)

    def test_registers_stable_shell_and_changes_only_requested_account(self):
        result = self.apply()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(self.shells.read_text().splitlines(), ['/bin/bash',str(self.shell)])
        self.assertEqual(json.loads((self.root/'events').read_text()), ['--shell',str(self.shell),'tester'])

    def test_current_registered_shell_needs_no_sudo(self):
        self.env['TEST_CURRENT'] = str(self.shell)
        self.env['TEST_SUDO_FAIL'] = '1'
        self.shells.write_text(str(self.shell)+'\n')
        self.assertEqual(self.apply().returncode,0)
        self.assertFalse((self.root/'events').exists())

    def test_matching_unregistered_shell_is_registered_without_usermod(self):
        self.env['TEST_CURRENT'] = str(self.shell)
        self.assertEqual(self.apply().returncode,0)
        self.assertIn(str(self.shell),self.shells.read_text())
        self.assertFalse((self.root/'events').exists())

    def test_sudo_failure_does_not_edit_shells(self):
        self.env['TEST_SUDO_FAIL'] = '1'
        self.assertEqual(self.apply().returncode,41)
        self.assertEqual(self.shells.read_text(),'/bin/bash')

    def test_usermod_failure_is_not_hidden(self):
        self.env['TEST_USERMOD_FAIL'] = '1'
        self.assertEqual(self.apply().returncode,42)

    def test_wrong_user_missing_shell_and_invalid_arguments_rejected(self):
        self.assertNotEqual(self.apply(username='other').returncode,0)
        self.assertNotEqual(self.apply(shell='/nonexistent/zsh').returncode,0)
        self.assertNotEqual(self.apply(username='bad:name').returncode,0)
        self.assertFalse((self.root/'events').exists())

if __name__ == '__main__': unittest.main(verbosity=2)
