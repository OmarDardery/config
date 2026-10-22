"""Exercise update ordering, failures and locking without changing a real profile."""
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "pkgs/config-update.sh"


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "commands.jsonl"
        self.checkout = self.root / "checkout with spaces" / "nixos"
        (self.checkout / "native").mkdir(parents=True)
        self.hardware = self.checkout / "hardware-configuration.nix"
        self.hardware.write_text("existing local hardware\n")
        self.system_hardware = self.root / "system-hardware.nix"
        self.system_hardware.write_text("generated system hardware\n")
        helper = SCRIPT.parents[1] / "native/copy-hardware.sh"
        (self.checkout / "native/copy-hardware.sh").write_text(
            helper.read_text().replace("/etc/nixos/hardware-configuration.nix", str(self.system_hardware))
        )
        for command in ("nix", "nh", "flatpak"):
            path = self.bin / command
            path.write_text(
                f"#!{shutil.which('python3')}\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "name = Path(sys.argv[0]).name\n"
                "with open(os.environ['UPDATE_LOG'], 'a') as log:\n"
                "    log.write(json.dumps([name, *sys.argv[1:]]) + '\\n')\n"
                "sys.exit(19 if name == os.environ.get('UPDATE_FAIL') else 0)\n"
            )
            path.chmod(0o755)

    def run_update(self, arguments=None, failure="", path=None):
        return subprocess.run(
            ["bash", str(SCRIPT), *(arguments if arguments is not None else [str(self.checkout), "os", "host"])],
            stdin=subprocess.DEVNULL,
            text=True,
            capture_output=True,
            env={
                **os.environ,
                "PATH": path if path is not None else str(self.bin) + ":" + os.environ["PATH"],
                "XDG_CACHE_HOME": str(self.root / "cache"),
                "UPDATE_LOG": str(self.log),
                "UPDATE_FAIL": failure,
            },
        )

    def commands(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_os_updates_in_order_without_an_extra_confirmation(self):
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [
            ["nix", "flake", "update", "--flake", f"path:{self.checkout}"],
            ["nh", "os", "switch", "--show-activation-logs", "--hostname", "host", f"path:{self.checkout}"],
            ["flatpak", "update", "--noninteractive", "--assumeyes"],
        ])
        self.assertIn("completed", result.stdout)

    def test_missing_hardware_is_restored_before_nix_runs(self):
        self.hardware.unlink()
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.hardware.read_text(), self.system_hardware.read_text())
        self.assertLess(result.stdout.index("Copied"), result.stdout.index("Updating flake inputs"))

    def test_existing_local_hardware_is_not_overwritten(self):
        self.system_hardware.unlink()
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.hardware.read_text(), "existing local hardware\n")

    def test_missing_hardware_source_stops_before_lockfile_changes(self):
        self.hardware.unlink()
        self.system_hardware.unlink()
        result = self.run_update()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.commands(), [])
        self.assertIn("nixos-generate-config", result.stderr)

    def test_home_update_does_not_require_hardware_or_copy_helper(self):
        shutil.rmtree(self.checkout)
        result = self.run_update([str(self.checkout), "home", "user"])
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_home_profile_and_prefixed_repository(self):
        result = self.run_update(["path:/checkout 'quoted'", "home", "user@host"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands()[1], [
            "nix", "run", "path:/checkout 'quoted'#home-manager", "--", "switch", "--flake", "path:/checkout 'quoted'#user@host"
        ])
        self.assertNotIn("path:path:", self.log.read_text())

    def test_missing_native_flatpak_is_skipped(self):
        (self.bin / "flatpak").unlink()
        for name in ("bash", "mkdir", "flock"):
            (self.bin / name).symlink_to(shutil.which(name))
        result = self.run_update(["/checkout", "home", "user"], path=str(self.bin))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([entry[0] for entry in self.commands()], ["nix", "nix"])
        self.assertIn("Flatpak is not installed; skipping", result.stdout)

    def test_nix_failures_stop_later_stages(self):
        for command, expected in (("nix", ["nix"]), ("nh", ["nix", "nh"])):
            with self.subTest(command=command):
                self.log.unlink(missing_ok=True)
                result = self.run_update(failure=command)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual([entry[0] for entry in self.commands()], expected)
                self.assertNotIn("completed", result.stdout)

    def test_flatpak_failure_reports_partial_success(self):
        result = self.run_update(failure="flatpak")
        self.assertEqual(result.returncode, 1)
        self.assertEqual([entry[0] for entry in self.commands()], ["nix", "nh", "flatpak"])
        self.assertIn("configuration activated, but Flatpak updates failed", result.stderr)
        self.assertNotIn("completed", result.stdout)

    def test_failure_releases_the_update_lock(self):
        self.assertNotEqual(self.run_update(failure="nh").returncode, 0)
        self.assertEqual(self.run_update().returncode, 0)

    def test_invalid_arguments_and_help_do_not_run_tools(self):
        for arguments in ([], ["repo"], ["repo", "os"], ["", "os", "host"],
                          ["repo", "bad", "host"], ["repo", "os", "bad/name"],
                          ["repo", "home", "profile", "extra"]):
            with self.subTest(arguments=arguments):
                self.assertEqual(self.run_update(arguments).returncode, 2)
        self.assertEqual(self.run_update(["--help"]).returncode, 0)
        self.assertEqual(self.commands(), [])

    def test_concurrent_run_is_rejected_before_updating(self):
        directory = self.root / "cache/nix-config"
        directory.mkdir(parents=True)
        with (directory / "update.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.run_update()
        self.assertEqual(result.returncode, 1)
        self.assertIn("already running", result.stderr)
        self.assertEqual(self.commands(), [])


if __name__ == "__main__":
    unittest.main()
