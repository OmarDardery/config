"""Writable desktop state migrations; backups contain the exact original bytes."""
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile

from state_file import identity, replace, snapshot, sync_directory


def kitty(target, defaults, legacy_palette=None):
    original = snapshot(target, missing_ok=True)
    obsolete = [rb'~/\.local/state/noctalia/theme/kitty\.conf',
                rb'\$XDG_STATE_HOME/noctalia/theme/kitty\.conf']
    if legacy_palette is not None:
        obsolete.append(re.escape(os.fsencode(legacy_palette)))
    pattern = rb'(?m)^include[ \t]+(?:' + b'|'.join(obsolete) + rb')[ \t]*$'
    updated = defaults.read_bytes() if original is None else re.sub(
        pattern, b'include themes/noctalia.conf', original[0])
    replace(target, original, updated, preserve_mode=True)
    target.parent.joinpath("themes").mkdir(exist_ok=True)


def noctalia(target, marker):
    if snapshot(marker, missing_ok=True) is not None:
        return
    original = snapshot(target, missing_ok=True)
    if original is not None:
        import tomlkit
        document = tomlkit.parse(original[0].decode())
        templates = document.setdefault("theme", {}).setdefault("templates", {})
        ids = list(templates.get("builtin_ids", []))
        if "kitty" not in ids:
            ids.append("kitty")
        templates["builtin_ids"] = ids
        templates.get("user", {}).pop("kitty", None)
        replace(target, original, tomlkit.dumps(document).encode(), preserve_mode=True)
    replace(marker, None, b"kitty builtin migration v1\n")


def tablet(target, defaults):
    original = snapshot(target, missing_ok=True)
    desired = json.loads(defaults.read_bytes())
    current = json.loads(original[0]) if original is not None else desired
    expected = desired["Profiles"][0]
    profile = next((p for p in current["Profiles"] if p["Tablet"] == expected["Tablet"]), None)
    if profile is None:
        current["Profiles"].append(expected)
    else:
        profile.setdefault("Bindings", {})["AuxButtons"] = expected["Bindings"]["AuxButtons"]
    if original is None or json.loads(original[0]) != current:
        replace(target, original, (json.dumps(current, indent=2) + "\n").encode(), preserve_mode=True)


def writable_tree(root):
    # Never chmod through a preserved user symlink.
    for directory, dirs, files in os.walk(root, followlinks=False):
        os.chmod(directory, stat.S_IMODE(os.stat(directory).st_mode) | 0o700)
        for name in files:
            path = Path(directory) / name
            info = path.lstat()
            if stat.S_ISREG(info.st_mode):
                os.chmod(path, stat.S_IMODE(info.st_mode) | stat.S_IWUSR)


def kitty_directory(target):
    """Convert the legacy directory link, preserving a backup and rollback link."""
    if not target.is_symlink():
        return
    before = identity(target.lstat())
    destination = os.readlink(target)
    if not target.is_dir():
        raise ValueError(f"{target} is a dangling or non-directory symlink")
    # Reject special files and symlink configs before touching the live path.
    config_snapshot = snapshot(target / "kitty.conf", missing_ok=True)
    transaction = Path(tempfile.mkdtemp(prefix=f".{target.name}.migration-", dir=target.parent))
    parked = transaction / "original-link"
    replacement = transaction / "replacement"
    installed = False
    try:
        backup = Path(tempfile.mkdtemp(prefix=f"{target.name}.backup-", dir=target.parent))
        shutil.copytree(target, backup, symlinks=True, dirs_exist_ok=True)
        backup.chmod(0o700)
        sync_tree(backup)
        sync_directory(target.parent)
        shutil.copytree(target, replacement, symlinks=True)
        writable_tree(replacement)
        if (not target.is_symlink() or identity_link(target) != (before, destination)
                or snapshot(target / "kitty.conf", missing_ok=True) != config_snapshot):
            raise ValueError(f"{target} changed during migration; backup retained; retry")
        try:
            os.rename(target, parked)
            os.rename(replacement, target)
            installed = True
        except BaseException:
            if not parked.is_symlink():
                raise
            if os.path.lexists(target):
                raise RuntimeError(f"Cannot roll back {target}: path occupied; original link retained at {parked}")
            os.rename(parked, target)
            raise
        sync_directory(target.parent)
    finally:
        # A failed rollback must retain the original link for manual recovery.
        if parked.is_symlink() and not installed:
            print(f"Recovery link retained at {parked}", file=sys.stderr)
        else:
            remove_transaction(transaction)


def sync_tree(root):
    for directory, _, files in os.walk(root, followlinks=False):
        for name in files:
            path = Path(directory) / name
            if stat.S_ISREG(path.lstat().st_mode):
                fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
                try:
                    os.fsync(fd)
                finally:
                    os.close(fd)
        sync_directory(directory)


def remove_transaction(root):
    # Copied store directories can be read-only even when preparation failed.
    for directory, _, _ in os.walk(root, followlinks=False):
        fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            os.fchmod(fd, 0o700)
        finally:
            os.close(fd)
    shutil.rmtree(root)


def identity_link(path):
    return identity(path.lstat()), os.readlink(path)


if __name__ == "__main__":
    {"kitty": kitty, "kitty-directory": kitty_directory, "noctalia": noctalia, "tablet": tablet}[sys.argv[1]](
        *(Path(argument) for argument in sys.argv[2:]))
