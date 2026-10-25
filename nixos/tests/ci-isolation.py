"""Check that CI hardware stays disposable and Nix failures propagate."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("ci.sh")
FIXTURE = Path(__file__).with_name("fixtures") / "ci-hardware.nix"


class CiIsolation(unittest.TestCase):
    def run_ci(self, fail=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "checkout with spaces" / "nixos"
            (source / "tests/fixtures").mkdir(parents=True)
            (source / "tests/ci.sh").write_text(SCRIPT.read_text())
            (source / "tests/fixtures/ci-hardware.nix").write_bytes(FIXTURE.read_bytes())
            hardware = source / "hardware-configuration.nix"
            original = b"production hardware must remain unchanged\n"
            hardware.write_bytes(original)
            (source / "flake.lock").write_text("original lock\n")
            bin_dir = root / "bin"
            bin_dir.mkdir()
            mock = bin_dir / "nix"
            mock.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "args = sys.argv[1:]\n"
                "flake = next(a for a in args if a.startswith('path:'))\n"
                "path = Path(flake[5:].split('#')[0])\n"
                "assert 'CI-EVALUATION-ONLY' in (path / 'hardware-configuration.nix').read_text()\n"
                "assert (path / 'flake.lock').read_text() == 'original lock\\n'\n"
                "assert '--no-write-lock-file' in args\n"
                "with open(os.environ['CI_TEST_LOG'], 'a') as log:\n"
                "    log.write(json.dumps({'args': args, 'directory': str(path)}) + '\\n')\n"
                "if args[:2] == ['flake', 'check'] and os.environ.get('CI_TEST_FAIL'):\n"
                "    sys.exit(19)\n"
                "if args[0] == 'eval':\n"
                "    print('x86_64-linux', end='')\n"
            )
            mock.chmod(0o755)
            log = root / "log.jsonl"
            result = subprocess.run(
                ["bash", str(source / "tests/ci.sh")],
                env={**os.environ, "PATH": str(bin_dir) + ":" + os.environ["PATH"],
                     "CI_TEST_LOG": str(log), "CI_TEST_FAIL": "1" if fail else ""},
                text=True, capture_output=True,
            )
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertEqual(hardware.read_bytes(), original)
            self.assertEqual((source / 'flake.lock').read_text(), 'original lock\n')
            for call in calls:
                self.assertFalse(Path(call["directory"]).exists(), "Temporary checkout leaked")
            return result, calls

    def test_checks_use_temporary_hardware_and_cleanup(self):
        result, calls = self.run_ci()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call['args'][0] for call in calls], ['eval', 'flake', 'build'])
        outputs = calls[-1]['args']
        self.assertTrue(any(a.endswith('.portability') for a in outputs))
        self.assertTrue(any(a.endswith('.theme-rendering') for a in outputs))
        self.assertFalse(any(a.endswith('.nvidia-open') for a in outputs))

    def test_evaluation_failure_stops_build_and_cleans_up(self):
        result, calls = self.run_ci(fail=True)
        self.assertEqual(result.returncode, 19, result.stderr)
        self.assertEqual([call['args'][0] for call in calls], ['eval', 'flake'])


if __name__ == "__main__":
    unittest.main()
