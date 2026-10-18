"""Exercise the upstream Fastfetch color hook without editing user configuration."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = Path(sys.argv.pop(1))


class FastfetchThemes(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = self.root / 'config with spaces'
        self.config.mkdir()
        self.native = self.root / 'fastfetch'
        self.native.write_text(f'#!{sys.executable}\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n')
        self.native.chmod(0o755)

    def run_app(self, *args):
        return subprocess.run([
            'bash', str(ROOT / 'pkgs/noctalia-fastfetch.sh'), str(self.native),
            str(UPSTREAM / 'fastfetch/apply.sh'), str(self.config), *args,
        ], text=True, capture_output=True, check=True)

    def add_theme(self):
        directory = self.config / 'fastfetch/themes'
        directory.mkdir(parents=True)
        data = {'logo': {'color': {'1': '#abcdef', '2': '#124578'}},
                'display': {'color': {'keys': '#123456', 'title': '#654321'},
                            'percent': {'color': {'green': '#12ab34', 'yellow': '#abcd12', 'red': '#ab1234'}}}}
        (directory / 'noctalia.jsonc').write_text(json.dumps(data))

    def test_missing_palette_preserves_arguments(self):
        self.assertEqual(json.loads(self.run_app('--logo', 'a b.png').stdout), ['--logo', 'a b.png'])

    def test_themed_cli_keeps_jsonc_and_user_arguments(self):
        self.add_theme()
        config = self.config / 'fastfetch/config.jsonc'
        original = '// personal config\n{"modules":["OS", "Kernel"],}\n'
        config.write_text(original)
        result = json.loads(self.run_app('--logo', 'a b.png').stdout)
        self.assertEqual(result[result.index('--color-keys') + 1], '#123456')
        self.assertEqual(result[-2:], ['--logo', 'a b.png'])
        self.assertNotIn('--config', result)
        self.assertEqual(config.read_text(), original)

    def test_explicit_config_wins(self):
        self.add_theme()
        result = json.loads(self.run_app('--config', 'my config.jsonc').stdout)
        self.assertEqual(result, ['--config', 'my config.jsonc'])

    def test_broken_palette_falls_back_without_losing_user_config(self):
        self.add_theme()
        (self.config / 'fastfetch/themes/noctalia.jsonc').write_text('invalid JSON')
        self.assertEqual(json.loads(self.run_app('--pipe').stdout), ['--pipe'])


if __name__ == '__main__':
    unittest.main()
