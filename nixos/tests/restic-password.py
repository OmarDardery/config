"""Check persistent key creation, preservation, permissions and failure cleanup."""
import base64
import os
from pathlib import Path
import stat
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'pkgs/restic-password.sh'


class PasswordInitialization(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.password = self.root / 'home.password'

    def run_script(self, **overrides):
        return subprocess.run(['bash', str(SCRIPT)], capture_output=True,
                              env={**os.environ, 'STATE_DIRECTORY': str(self.root), **overrides})

    def test_random_private_password_is_created_once(self):
        self.assertEqual(self.run_script().returncode, 0)
        original = self.password.read_bytes()
        self.assertEqual(len(base64.b64decode(original)), 48)
        self.assertEqual(stat.S_IMODE(self.password.stat().st_mode), 0o600)
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual(self.password.read_bytes(), original)
        self.assertEqual(list(self.root.iterdir()), [self.password])

    def test_existing_empty_password_fails_without_replacement(self):
        self.password.touch()
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual(self.password.read_bytes(), b'')

    def test_failed_generation_never_publishes_partial_key(self):
        binaries = self.root / 'bin'
        binaries.mkdir()
        mock = binaries / 'openssl'
        mock.write_text(f'#!{shutil.which("bash")}\nprintf partial\nexit 19\n')
        mock.chmod(0o755)
        result = self.run_script(PATH=str(binaries) + ':' + os.environ['PATH'])
        self.assertEqual(result.returncode, 19)
        self.assertFalse(self.password.exists())
        self.assertEqual(list(self.root.iterdir()), [binaries])


if __name__ == '__main__':
    unittest.main()
