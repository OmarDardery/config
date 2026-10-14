#!/usr/bin/env python3
"""Test the real bootstrap confirmation with a PTY and mocked Nix/activation."""
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import subprocess
import sys
import termios
import time

fixture = Path(sys.argv[1])
bash = sys.argv[2]
base = {
    "PATH": str(fixture / "bin"), "HOME": str(fixture / "home"),
    "TMPDIR": str(fixture / "retention"),
    "MOCK_OS": "nixos", "MOCK_UID": "1000", "MOCK_USER": "fixture",
    "MOCK_UUID": "root-uuid", "MOCK_DEVICE_UUID": "root-uuid",
    "MOCK_ARCH": "x86_64", "MOCK_SYSTEM": "x86_64-linux",
    "MOCK_ROOT_TYPE": "xfs", "MOCK_BOOT_TYPE": "vfat", "MOCK_HM_ENTRY": "present",
    "MOCK_CONFIGURED_FLAKE": str(fixture / "checkout/nixos"),
    "MOCK_PROFILE_USER": "fixture", "MOCK_PROFILE_HOME": str(fixture / "home"),
    "MOCK_DEFAULT_PROFILE": "oad", "MOCK_DEFAULT_HOST": "nixos",
    "MOCK_PROFILE": "oad", "MOCK_HOST": "nixos", "MOCK_BACKUP_EXTENSION": "",
    "MOCK_BUILD": "ok", "MOCK_OUTPUT": str(fixture / "store/output"),
    "MOCK_STORE": str(fixture / "store"), "MOCK_FLAKE": f"path:{fixture}/checkout/nixos",
    "MOCK_LOG": str(fixture / "log"), "MOCK_ALLOW_SWITCH": "yes",
}
for mode in ("accept", "refuse", "eof", "switch-failure", "signal"):
    (fixture / "log").write_text("")
    master, slave = pty.openpty()

    def terminal():
        os.setsid()
        fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

    env = dict(base, MOCK_SWITCH_FAIL="yes" if mode == "switch-failure" else "no")
    process = subprocess.Popen(
        [bash, "--noprofile", "--norc", str(fixture / "bootstrap.sh"),
         "--repo-dir", str(fixture / "checkout"), "--activate"],
        env=env, stdin=slave, stdout=slave, stderr=slave, preexec_fn=terminal,
    )
    os.close(slave)
    output = b""
    try:
        deadline = time.monotonic() + 10
        while b"Activate NixOS now?" not in output:
            assert process.poll() is None, (mode, output)
            assert time.monotonic() < deadline, (mode, output)
            if select.select([master], [], [], 0.1)[0]:
                output += os.read(master, 65536)
        roots = list((fixture / "retention").glob("configs-bootstrap.*/result"))
        assert len(roots) == 1 and roots[0].is_symlink() and roots[0].is_dir(), mode
        assert "sudo" not in (fixture / "log").read_text(), mode
        if mode == "signal":
            process.send_signal(signal.SIGTERM)
        else:
            os.write(master, {"accept": b"y\n", "refuse": b"n\n", "eof": b"\x04",
                              "switch-failure": b"y\n"}[mode])
        status = process.wait(timeout=10)
        assert (status == 0) == (mode == "accept"), (mode, status)
        log = (fixture / "log").read_text()
        if mode in ("accept", "switch-failure"):
            assert "nix-env --profile" in log and "switch-to-configuration switch" in log, log
        else:
            assert "sudo" not in log and "nix-env" not in log, log
        assert not list((fixture / "retention").iterdir()), mode
        print(f"PASS: rooted NixOS confirmation and cleanup ({mode})")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)
