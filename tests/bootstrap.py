#!/usr/bin/env python3
"""Exercise the local Nix entry point without touching a live home."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
import json, os, pathlib, shutil, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
root = pathlib.Path(os.environ['TEST_ROOT'])
with (root/'events').open('a') as stream: stream.write(json.dumps([name, *args])+'\n')
if name == 'id': print('1000')
if name == 'git' and args[0] == 'clone': shutil.copytree(root/'template', args[-1])
'''


class Bootstrap(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root/'home with spaces'; self.home.mkdir()
        self.bin = self.root/'bin'; self.bin.mkdir()
        self.template = self.root/'template'; (self.template/'non-nixos').mkdir(parents=True)
        (self.template/'flake.nix').touch(); (self.template/'non-nixos/apply.sh').touch()
        self.marker = self.root/'NIXOS'
        self.source = (ROOT/'setup.sh').read_text().replace('/etc/NIXOS', str(self.marker))
        self.env = dict(os.environ, HOME=str(self.home), TEST_ROOT=str(self.root), PATH=f'{self.bin}:/usr/bin:/bin')
        for name in ['id', 'git', 'python3', 'nix']:
            path = self.bin/name; path.write_text(f'#!{sys.executable}\n'+STUB); path.chmod(0o755)

    def run_setup(self, *args, local=False):
        if local:
            repo = self.home/'existing checkout'; shutil.copytree(self.template, repo)
            script = repo/'setup.sh'; script.write_text(self.source)
            result = subprocess.run(['bash', str(script), *args], env=self.env, capture_output=True, text=True)
        else:
            result = subprocess.run(['bash', '-s', '--', *args], input=self.source, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        events = self.root/'events'
        return [json.loads(line) for line in events.read_text().splitlines()] if events.exists() else []

    def test_native_setup_only_requires_nix(self):
        calls = self.run_setup(local=True)
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][0], 'nix')
        self.assertIn('nix-command flakes', calls[0])
        self.assertIn(f'path:{self.home}/existing checkout', calls[0])
        self.assertIn('--repo-dir', calls[0])

    def test_options_are_forwarded_unchanged(self):
        calls = self.run_setup('--ref', 'feature/setup', '--update', local=True)
        self.assertEqual(calls[0][-3:], ['--ref', 'feature/setup', '--update'])

    def test_nixos_uses_the_same_entry_point(self):
        self.marker.touch()
        calls = self.run_setup('--hardware', 'generic', local=True)
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][0], 'nix')
        self.assertEqual(calls[0][-2:], ['--hardware', 'generic'])


if __name__ == '__main__': unittest.main(verbosity=2)
