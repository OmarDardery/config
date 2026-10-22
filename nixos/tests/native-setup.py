#!/usr/bin/env python3
"""Exercise native config merging and installers using disposable host fixtures."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("native_configure", ROOT / "native/configure.py")
configure = importlib.util.module_from_spec(spec)
spec.loader.exec_module(configure)


class NativeSetup(unittest.TestCase):
    def test_config_merge_and_idempotence(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "greetd.toml").write_text(
                '# keep this comment\n[terminal]\nvt = 2\n[default_session]\n'
                'command = "old-greeter"\nuser = "greeter"\n[initial_session]\n'
                'command = "old-autologin"\nuser = "someone"\n'
            )
            (directory / "greeter.toml").write_text('[appearance]\nfont = "Custom"\n')
            configure.configure(directory, "fixture", "_greetd")
            first = {file.name: file.read_bytes() for file in directory.iterdir()}
            document = tomllib.loads((directory / "greetd.toml").read_text())
            self.assertEqual(document["terminal"]["vt"], 2)
            self.assertNotIn("initial_session", document)
            self.assertEqual(document["default_session"], {
                "command": "/usr/bin/noctalia-greeter-session", "user": "_greetd"
            })
            greeter = tomllib.loads((directory / "greeter.toml").read_text())
            self.assertEqual(greeter["appearance"]["font"], "Custom")
            self.assertEqual(greeter["session"]["default"], "umbriel")
            self.assertEqual(greeter["user"]["default"], "fixture")
            self.assertIn("# keep this comment", (directory / "greetd.toml").read_text())
            self.assertIn("subject.local && subject.active", (directory / "greeter.rules").read_text())
            configure.configure(directory, "fixture", "_greetd")
            self.assertEqual(first, {file.name: file.read_bytes() for file in directory.iterdir()})

    def test_invalid_account_is_rejected_before_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                configure.configure(Path(directory), 'bad"account', "greeter")
            self.assertEqual(list(Path(directory).iterdir()), [])

    def test_hardware_copy_preserves_source_and_backs_up_symlink(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            repo = directory / "repo"
            (repo / "nixos").mkdir(parents=True)
            source = directory / "source.nix"
            source.write_text("generated hardware\n")
            original = directory / "old.nix"
            original.write_text("previous hardware\n")
            target = repo / "nixos/hardware-configuration.nix"
            target.symlink_to(original)
            script = directory / "copy-hardware.sh"
            script.write_text((ROOT / "native/copy-hardware.sh").read_text().replace(
                "/etc/nixos/hardware-configuration.nix", str(source)))
            env = dict(os.environ, HOME=str(directory / "home"), XDG_STATE_HOME=str(directory / "state"))
            subprocess.run(["bash", str(script), str(repo)], env=env, check=True, capture_output=True)
            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_text(), source.read_text())
            self.assertEqual(original.read_text(), "previous hardware\n")
            backups = list((directory / "state/config-backups").iterdir())
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), original.read_text())
            subprocess.run(["bash", str(script), str(repo)], env=env, check=True, capture_output=True)
            self.assertEqual(len(list(backups[0].parent.iterdir())), 1)
            source.unlink()
            result = subprocess.run(["bash", str(script), str(repo)], env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(target.read_text(), "generated hardware\n")

    def test_native_apply_orders_login_handoff_after_home_activation(self):
        for fail_home, fail_greeter in ((False, False), (True, False), (False, True)):
            with self.subTest(fail_home=fail_home, fail_greeter=fail_greeter), tempfile.TemporaryDirectory() as temporary:
                directory = Path(temporary)
                repo = directory / "repo"
                native = repo / "nixos/native"
                native.mkdir(parents=True)
                shutil.copyfile(ROOT / "native/configure.py", native / "configure.py")
                bootstrap = repo / "nixos/bootstrap.sh"
                bootstrap.write_text('printf "HOME-ACTIVATE\\n" >> "$TEST_LOG"; exit "$FAIL_HOME"\n')
                home = directory / "home"
                (home / ".local/bin").mkdir(parents=True)
                desktop = home / ".local/bin/desktop-apply"
                desktop.write_text('#!/usr/bin/env bash\nprintf "DESKTOP-APPLY\\n" >> "$TEST_LOG"\n')
                desktop.chmod(0o755)
                work = directory / "work"
                work.mkdir()
                host = directory / "host"
                host.mkdir()
                # Only absolute host paths are redirected; orchestration is unchanged.
                common = (ROOT / "native/common.sh").read_text()
                paths = ("/etc/pam.d/greetd", "/usr/share/wayland-sessions/umbriel.desktop",
                         "/etc/greetd/config.toml", "/var/lib/noctalia-greeter/greeter.toml",
                         "/etc/polkit-1/rules.d/49-noctalia-greeter-config.rules",
                         "/etc/systemd/user/config-desktop-apply.service")
                for original in paths:
                    target = host / original.lstrip("/")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if original.endswith("config.toml"):
                        target.write_text('[default_session]\ncommand="old"\nuser="greeter"\n')
                    elif original.endswith("greeter.toml"):
                        target.write_text("")
                    else:
                        target.touch()
                    common = common.replace(original, str(target))
                script = directory / "apply.sh"
                script.write_text(common + r'''
nix() { if [[ " $* " == *" eval "* ]]; then printf 'oad\n'; fi; }
start-umbriel() { :; }
noctalia() { :; }
noctalia-greeter-session() { :; }
noctalia-greeter-apply-appearance() { :; }
id() { case "$1" in -un) printf 'fixture\n';; -gn) printf 'greeter\n';; esac; }
getent() { return 0; }
systemctl() { printf 'USER %s\n' "$*" >> "$TEST_LOG"; }
sudo() {
  printf 'ROOT %s\n' "$*" >> "$TEST_LOG"
  case "$1" in
    systemctl)
      [[ " $* " != *" enable greetd.service "* || "$FAIL_GREETER" != 1 ]] || return 42
      return 0 ;;
    noctalia-greeter-apply-appearance)
      [[ "$2" != --print-greeter-user ]] || printf 'greeter\n' ;;
    cat) shift; cat "$@" ;;
    test) shift; test "$@" ;;
    *) exit 99 ;;
  esac
}
native_install_file() { mkdir -p "${2%/*}"; cp "$1" "$2"; }
previous_display_manager=/usr/lib/systemd/system/gdm.service
native_apply
''')
                log = directory / "log"
                env = dict(os.environ, HOME=str(home), repo_dir=str(repo), work=str(work),
                           TEST_LOG=str(log), FAIL_HOME="42" if fail_home else "0",
                           FAIL_GREETER="1" if fail_greeter else "0")
                result = subprocess.run(["bash", str(script)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 42 if fail_home else (1 if fail_greeter else 0), result.stderr)
                text = log.read_text()
                if fail_home:
                    self.assertNotIn("disable gdm.service", text)
                    self.assertNotIn("enable greetd.service", text)
                else:
                    self.assertLess(text.index("HOME-ACTIVATE"), text.index("disable gdm.service"))
                    self.assertLess(text.index("DESKTOP-APPLY"), text.index("enable greetd.service"))
                    self.assertNotIn("--now greetd", text)
                    self.assertNotIn("stop gdm", text)
                    if fail_greeter:
                        self.assertIn("enable gdm.service", text)
                        self.assertNotIn("set-default graphical.target", text)
                    config = tomllib.loads((host / "etc/greetd/config.toml").read_text())
                    self.assertEqual(config["default_session"]["command"], "/usr/bin/noctalia-greeter-session")

    def test_distribution_installers(self):
        for distribution in ("debian", "fedora"):
            with self.subTest(distribution=distribution), tempfile.TemporaryDirectory() as temporary:
                directory = Path(temporary)
                repo = directory / "repo"
                native = repo / "nixos/native"
                native.mkdir(parents=True)
                script = native / f"{distribution}.sh"
                shutil.copyfile(ROOT / "native" / script.name, script)
                release = directory / "os-release"
                release.write_text(f'ID={distribution}\nVERSION_ID=44\nVERSION_CODENAME=trixie\n')
                common = (ROOT / "native/common.sh").read_text().replace(". /etc/os-release", f'. "{release}"')
                # Package orchestration stops at the shared apply boundary; actual
                # Home Manager/NixOS switching is covered by bootstrap.sh tests.
                common += '\nnative_apply() { printf "APPLY\\n" >> "$TEST_LOG"; }\n'
                (native / "common.sh").write_text(common)
                commands = directory / "bin"
                commands.mkdir()
                mock = commands / "mock"
                mock.write_text('''#!/usr/bin/env bash
set -euo pipefail
name=${0##*/}
printf '%s' "$name" >> "$TEST_LOG"
printf ' %q' "$@" >> "$TEST_LOG"
printf '\\n' >> "$TEST_LOG"
case "$name" in
 id) [[ "$1" == -u ]] && printf '1000\\n' ;;
 sudo) # Never execute privileged commands, including package maintainers.
   case "${1:-}" in -v|apt-get|dnf|dpkg|install) ;; test|cmp) exit 1 ;; *) exit 99 ;; esac ;;
 curl) while (($#)); do if [[ "$1" == -o ]]; then printf 'download fixture\\n' > "$2"; break; fi; shift; done ;;
esac
''')
                mock.chmod(0o755)
                for name in ("sudo", "curl", "id"):
                    (commands / name).symlink_to(mock)
                log = directory / "log"
                home = directory / "home"
                home.mkdir()
                env = dict(os.environ, HOME=str(home), PATH=f"{commands}:{os.environ['PATH']}", TEST_LOG=str(log))
                result = subprocess.run(["bash", str(script)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                text = log.read_text()
                self.assertTrue(text.endswith("APPLY\n"))
                self.assertIn("noctalia-greeter", text)
                self.assertIn("umbriel-nightly" if distribution == "fedora" else "trixie-backports", text)
                self.assertNotIn("--nogpgcheck", text)
                self.assertIn("firefox", text)
                self.assertNotIn("curl |", text)


if __name__ == "__main__":
    unittest.main()
