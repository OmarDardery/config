#!/usr/bin/env python3
"""Refresh per-user sandbox caches without changing Flatpak permissions/data."""

import os
from pathlib import Path
import subprocess
import sys


def refresh(fonts):
    font_set = str(Path(fonts).resolve(strict=True))
    state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    stamps = state / "flatpak-font-cache"
    stamps.mkdir(parents=True, exist_ok=True)
    failed = False
    for scope in ("user", "system"):
        listing = subprocess.run(
            ["flatpak", "list", f"--{scope}", "--app", "--columns=ref"],
            text=True, capture_output=True, check=True,
        )
        for ref in listing.stdout.splitlines():
            ref = ref.strip()
            if not ref:
                continue
            # Query the installed commit so updates also invalidate the stamp.
            commit = subprocess.run(
                ["flatpak", "info", f"--{scope}", "--show-commit", ref],
                text=True, capture_output=True, check=True,
            ).stdout.strip()
            key = f"v1\n{font_set}\n{commit}\n"
            stamp = stamps / (scope + "-" + ref.replace("/", "_"))
            if stamp.is_file() and stamp.read_text() == key:
                continue
            result = subprocess.run(
                ["flatpak", "run", f"--{scope}", "--command=fc-cache", ref, "-r"],
                check=False,
            )
            if result.returncode:
                print(f"Font cache refresh failed for {scope} {ref}; will retry.", file=sys.stderr)
                failed = True
                continue
            temporary = stamp.with_suffix(".tmp")
            temporary.write_text(key)
            temporary.replace(stamp)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(refresh(sys.argv[1]))
