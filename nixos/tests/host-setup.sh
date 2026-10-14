#!/usr/bin/env bash
# Hermetic host checks, including /dev/tty confirmation using a real disposable PTY.
set -euo pipefail
root=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd)
python3 - "$root" << 'PY'
import errno
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import shutil
import subprocess
import sys
import tempfile
import termios
import time

root = Path(sys.argv[1])
bash = shutil.which("bash")
assert bash
cases = 0
with tempfile.TemporaryDirectory(prefix="host-setup-test-") as directory:
    tmp = Path(directory)
    commands = tmp / "bin"
    commands.mkdir()
    release = tmp / "os-release"
    marker = tmp / "installed"
    log = tmp / "log"
    ostree = tmp / "ostree-booted"
    bootstrap = tmp / "bootstrap.sh"
    bootstrap.write_text((root / "bootstrap.sh").read_text())
    helper = (root / "bootstrap-host.sh").read_text()
    seams = {
        "/etc/os-release": str(release),
        "/run/ostree-booted": str(ostree),
        "/sysroot/ostree": str(tmp / "sysroot-ostree"),
        "/ostree": str(tmp / "ostree"),
    }
    for original in seams:
        assert original in helper, f"missing filesystem seam: {original}"
    helper = re.sub("|".join(map(re.escape, seams)), lambda match: seams[match[0]], helper)
    (tmp / "bootstrap-host.sh").write_text(helper)
    mock = commands / "mock"
    mock.write_text("#!" + bash + r'''
set -euo pipefail
name=${0##*/}
printf '%s' "$name" >> "$LOG"
printf ' %q' "$@" >> "$LOG"
printf '\n' >> "$LOG"
case "$name" in
  id) [[ "$*" == -u ]] || exit 90; printf '%s\n' "$UID_FIXTURE" ;;
  uname) [[ "$*" == -s ]] || exit 90; printf '%s\n' "$KERNEL" ;;
  systemctl)
    case "$*" in
      --version) printf 'systemd %s (mock)\n' "$CLI_VERSION" ;;
      'show --property=Version --value') printf '%s\n' "$MANAGER_VERSION" ;;
      '--user show-environment') [[ "$USER_MANAGER" == yes ]] ;;
      'show --property=LoadState --value '*|'--user show --property=LoadState --value '*)
        printf '%s\n' "$LOAD_STATE" ;;
      'is-active '*|'--user is-active '*) printf 'inactive\n'; exit 3 ;;
      *) exit 90 ;;
    esac ;;
  rpm|dpkg-query)
    if [[ "$name" == rpm ]]; then
      [[ $# == 3 && "$1 $2" == '-q --' ]] || exit 90
      package=$3
    else
      [[ $# == 4 && "$1" == -W && "$2" == '-f=${Status}' && "$3" == -- ]] || exit 90
      package=$4
    fi
    if [[ "$ALL_INSTALLED" == yes && "$package" != "$MISSING_PACKAGE" || -e "$MARKER" || "$package" == "$INSTALLED_PACKAGE" ]]; then
      [[ "$name" != dpkg-query ]] || printf 'install ok installed'
      exit 0
    fi
    [[ "$name" != dpkg-query ]] || printf 'deinstall ok config-files'
    exit 1 ;;
  apt-cache)
    [[ $# == 2 && "$1" == policy ]] || exit 90
    if [[ "$CANDIDATES" == yes && "$2" != "$UNAVAILABLE_PACKAGE" ]]; then printf '  Candidate: 1.0-1\n'; else printf '  Candidate: (none)\n'; fi ;;
  dnf)
    if [[ $# == 4 && "$1 $2 $3" == '--cacheonly list --available' ]]; then
      [[ "$CANDIDATES" == yes && "$4" != "$UNAVAILABLE_PACKAGE" ]]; exit
    fi
    [[ $# -gt 3 && "$1 $2 $3" == '--setopt=install_weak_deps=False --setopt=obsoletes=False install' ]] || exit 90
    [[ "$IN_SUDO" == yes ]] || exit 90
    [[ "$INSTALL_FAILURE" == no ]] || exit 42
    [[ "$VERIFY_FAILURE" == yes ]] || printf 'installed\n' > "$MARKER" ;;
  apt-get)
    [[ $# -gt 3 && "$1 $2 $3" == '--no-remove --no-install-recommends install' && "$IN_SUDO" == yes ]] || exit 90
    [[ "$INSTALL_FAILURE" == no ]] || exit 42
    [[ "$VERIFY_FAILURE" == yes ]] || printf 'installed\n' > "$MARKER" ;;
  sudo)
    [[ "$1" == dnf || "$1" == apt-get ]] || exit 90
    IN_SUDO=yes "$@" ;;
  *) exit 90 ;;
esac
''')
    mock.chmod(0o755)
    for command in ("id", "uname", "systemctl", "rpm", "dpkg-query", "apt-cache",
                    "dnf", "apt-get", "sudo", "git", "nix", "login", "firewall-cmd"):
        (commands / command).symlink_to("mock")

    def run(label, flags=("--setup-host",), *, distro="fedora", data=None,
            success=True, contains=None, answer=None, sudo=False, atomic=False,
            relative=False, **values):
        global cases
        release.write_text(data if data is not None else f'ID="{distro}"\n')
        marker.unlink(missing_ok=True)
        ostree.unlink(missing_ok=True)
        if atomic:
            ostree.touch()
        log.write_text("")
        env = dict(PATH=str(commands), HOME=str(tmp / "home"), LOG=str(log), MARKER=str(marker),
                   UID_FIXTURE="1000", KERNEL="Linux", CLI_VERSION="257", MANAGER_VERSION="257.1",
                   USER_MANAGER="yes", LOAD_STATE="loaded", ALL_INSTALLED="no", INSTALLED_PACKAGE="",
                   CANDIDATES="yes", UNAVAILABLE_PACKAGE="", MISSING_PACKAGE="",
                   IN_SUDO="no", INSTALL_FAILURE="no", VERIFY_FAILURE="no")
        env.update(values)
        command = [bash, "--noprofile", "--norc", "bootstrap.sh" if relative else str(bootstrap), *flags]
        if answer is None:
            result = subprocess.run(command, env=env, stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    timeout=10, start_new_session=True, cwd=tmp)
            status, output = result.returncode, result.stdout.decode()
        else:
            master, slave = pty.openpty()

            def terminal():
                os.setsid()
                fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

            process = subprocess.Popen(command, env=env, stdin=slave, stdout=slave,
                                       stderr=slave, preexec_fn=terminal, cwd=tmp)
            os.close(slave)
            output = b""
            sent = False
            deadline = time.monotonic() + 10
            try:
                while True:
                    if time.monotonic() > deadline:
                        raise AssertionError(f"{label}: PTY timeout")
                    if not select.select([master], [], [], 0.1)[0]:
                        continue
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as error:
                        if error.errno == errno.EIO:
                            break
                        raise
                    if not chunk:
                        break
                    output += chunk
                    if b"Type yes: " in output and not sent:
                        os.write(master, answer.encode() + b"\n")
                        sent = True
                status = process.wait(timeout=2)
                output = output.decode()
            finally:
                os.close(master)
                if process.poll() is None:
                    process.kill()
                    process.wait()
        assert (status == 0) == success, (label, status, output)
        if contains:
            assert contains in output, (label, output)
        trace = log.read_text()
        names = [line.split(" ")[0] for line in trace.splitlines()]
        assert not set(names) & {"git", "nix", "login", "firewall-cmd"}, (label, trace)
        assert names.count("sudo") == int(sudo), (label, trace)
        assert not (tmp / "home").exists(), "host path created checkout/home"
        if sudo:
            assert trace.index("sudo ") > trace.index("--available" if distro == "fedora" else "apt-cache policy")
        cases += 1
        print(f"PASS: {label}")
        return output, trace

    for distro, packages in {
        "fedora": ["polkit", "polkit-gnome", "pam", "systemd-pam", "gnome-keyring", "gnome-keyring-pam", "udisks2", "gvfs", "bluez", "upower"],
        "debian": ["polkitd", "policykit-1-gnome", "libpam-systemd", "dbus-user-session", "gnome-keyring", "libpam-gnome-keyring", "udisks2", "gvfs", "bluez", "upower"],
    }.items():
        output, trace = run(f"{distro} preview without Nix", distro=distro)
        assert "Proposed command:" in output
        proposed = output.split("Proposed command:")[1].splitlines()[0].split()
        assert proposed[proposed.index("install") + 1:] == packages
        assert "native polkit-gnome-authentication-agent-1 autostart as your normal user" in output
        assert "does not configure or launch the agent" in output
        assert "flatpak" not in trace and "docker" not in trace
        agent = packages[1]
        output, trace = run(f"{distro} only native agent missing", distro=distro,
                            ALL_INSTALLED="yes", MISSING_PACKAGE=agent)
        assert output.split("Proposed command:")[1].splitlines()[0].endswith(f" install {agent}")
        candidate_query = f"dnf --cacheonly list --available {agent}" if distro == "fedora" else f"apt-cache policy {agent}"
        assert candidate_query + "\n" in trace
        for flags in (("--setup-host",), ("--setup-host", "--apply-host")):
            output, trace = run(f"{distro} missing native agent candidate {' '.join(flags)}", flags,
                                distro=distro, ALL_INSTALLED="yes", MISSING_PACKAGE=agent,
                                UNAVAILABLE_PACKAGE=agent, success=False, contains=f"candidate for {agent}")
            assert candidate_query + "\n" in trace
            assert "Type yes:" not in output
        run(f"{distro} already installed", distro=distro, ALL_INSTALLED="yes",
            contains="already installed")
        run(f"{distro} apply no-op without terminal", ("--setup-host", "--apply-host"),
            distro=distro, ALL_INSTALLED="yes")
        run(f"{distro} unavailable candidates", distro=distro, CANDIDATES="no",
            success=False, contains="candidate")
        run(f"{distro} apply refuses unavailable candidates before confirmation",
            ("--setup-host", "--apply-host"), distro=distro, CANDIDATES="no",
            success=False, contains="candidate")
        output, trace = run(f"{distro} only missing packages", distro=distro, INSTALLED_PACKAGE=packages[0])
        assert packages[0] not in output.split("Proposed command:")[1].splitlines()[0].split()
        run(f"{distro} no terminal", ("--setup-host", "--apply-host"), distro=distro,
            success=False, contains="interactive terminal required")
        run(f"{distro} decline on PTY", ("--setup-host", "--apply-host"), distro=distro,
            answer="no", success=False, contains="cancelled")
        run(f"{distro} nonexact confirmation", ("--setup-host", "--apply-host"), distro=distro,
            answer="y", success=False, contains="cancelled")
        output, trace = run(f"{distro} accept on PTY and verify", ("--setup-host", "--apply-host"),
                            distro=distro, answer="yes", sudo=True, contains="NOT been certified")
        sudo_command = next(line.split() for line in trace.splitlines() if line.startswith("sudo "))
        assert sudo_command[sudo_command.index("install") + 1:] == packages
        run(f"{distro} package command failure", ("--setup-host", "--apply-host"),
            distro=distro, answer="yes", sudo=True, INSTALL_FAILURE="yes", success=False)
        run(f"{distro} post-install verification failure", ("--setup-host", "--apply-host"),
            distro=distro, answer="yes", sudo=True, VERIFY_FAILURE="yes", success=False,
            contains="verification failed")

    run("apply requires setup", ("--apply-host",), success=False, contains="requires --setup-host")
    for flags in (("--activate",), ("--build-only",), ("--profile", "oad"),
                  ("--host", "nixos"), ("--backup-extension", "bak"), ("--install-nix",)):
        run(f"exclusive {' '.join(flags)}", ("--setup-host", *flags), success=False, contains="exclusive")
    run("repo ignored even if absent", ("--setup-host", "--repo-dir", str(tmp / "absent?repo")))
    run("root guard", UID_FIXTURE="0", success=False, contains="not root")
    run("Linux guard", KERNEL="Darwin", success=False, contains="Linux")
    for distro in ("ubuntu", "nixos", "rhel", "linuxmint", "", "Fedora"):
        run(f"exact ID refusal: {distro!r}", distro=distro, success=False, contains="unsupported host")
    for variant in ("silverblue", "kinoite", "coreos", "iot", "unknown"):
        run(f"unsupported variant {variant}", data=f"ID=fedora\nVARIANT_ID={variant}\n",
            success=False, contains="unsupported host")
    for variant in ("workstation", "server"):
        run(f"supported Fedora {variant}", data=f"ID='fedora'\nVARIANT_ID=\"{variant}\"\n")
    run("OSTree refusal", atomic=True, success=False, contains="OSTree/Atomic")
    run("OSTree apply refusal", ("--setup-host", "--apply-host"), atomic=True,
        success=False, contains="OSTree/Atomic")
    run("unsupported variant apply refusal", ("--setup-host", "--apply-host"),
        data="ID=fedora\nVARIANT_ID=silverblue\n", success=False, contains="unsupported host")
    run("ID_LIKE is not support", data="ID=ubuntu\nID_LIKE=debian\n", success=False, contains="unsupported host")
    for data in ('ID="$(sudo evil)"\n', 'ID=`sudo evil`\n', 'ID=fedora;sudo evil\n',
                 'ID="fedora\\x"\n', 'ID="fedora\n', 'ID=fedora\nID=debian\n',
                 'ID=fedora\nVARIANT_ID=server\nVARIANT_ID=workstation\n'):
        run(f"safe parser {data!r}", data=data, success=False)
    run("ignored shell expressions", data='ID=fedora\nNAME="$(sudo evil)"\n')
    run("Debian 12 systemd diagnosis", distro="debian", CLI_VERSION="252", success=False,
        contains="Debian 12")
    run("old systemd apply refused", ("--setup-host", "--apply-host"), CLI_VERSION="253",
        success=False, contains="unsupported")
    run("old running systemd refused", MANAGER_VERSION="252.9", success=False, contains="reboot manually")
    run("malformed version", CLI_VERSION="not-a-version", success=False, contains="cannot parse")
    run("malformed manager version", MANAGER_VERSION="garbage", success=False, contains="cannot parse")
    run("systemd 254 minimum", CLI_VERSION="254", MANAGER_VERSION="254")
    run("distro-formatted manager version", MANAGER_VERSION="257 (257.1-1)")
    run("bootstrap invoked without slash", relative=True)
    run("missing unit diagnostic", LOAD_STATE="not-found", contains="not-found")
    run("missing user manager diagnostic", USER_MANAGER="no", contains="no working systemd user manager")
    run("overflow version rejected", CLI_VERSION="9999999999999999999999", success=False, contains="cannot parse")
    for command, distro in (("rpm", "fedora"), ("dnf", "fedora"),
                            ("dpkg-query", "debian"), ("apt-cache", "debian"),
                            ("apt-get", "debian"), ("systemctl", "fedora"), ("sudo", "fedora")):
        (commands / command).unlink()
        try:
            run(f"missing required tool {command}", ("--setup-host", "--apply-host"),
                distro=distro, success=False)
        finally:
            (commands / command).symlink_to("mock")
    assert cases == 83, f"expected original 77 cases plus 6 native-agent cases, got {cases}"
    print(f"All {cases} hermetic host-setup cases passed (including PTY confirmations).")
PY
