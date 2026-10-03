#!/usr/bin/env python3
"""Remove redundant or explicitly reset Noctalia state overrides."""

import argparse
from collections.abc import Mapping
import os
from pathlib import Path
import stat
import tempfile
import time
import tomllib

import tomlkit


def snapshot(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    info = os.fstat(fd)
    if not stat.S_ISREG(info.st_mode):
        os.close(fd)
        raise ValueError("state must be a regular, non-symlink file")
    with os.fdopen(fd, "rb") as source:
        identity = (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns,
                    info.st_ctime_ns, info.st_mode)
        return source.read(), identity


def equal(left, right):
    if isinstance(left, Mapping) and isinstance(right, Mapping):
        return left.keys() == right.keys() and all(equal(left[k], right[k]) for k in left)
    if isinstance(left, list) and isinstance(right, list):
        return len(left) == len(right) and all(equal(a, b) for a, b in zip(left, right))
    if isinstance(left, bool) or isinstance(right, bool):
        return type(left) is type(right) and left == right
    return left == right


def reconcile(state, desired, *, apply=False, resets=()):
    state = Path(state)
    reset_paths = {tuple(path.split(".")) for path in resets}
    if any(not all(path) for path in reset_paths):
        raise ValueError("reset paths must have nonempty dotted components")
    with open(desired, "rb") as source:
        wanted = tomllib.load(source)
    original, identity = snapshot(state)
    document = tomlkit.parse(original.decode("utf-8"))
    removed = []

    def at(path):
        table = document
        for key in path:
            table = table[key]
        return table

    def prune(target, prefix=()):
        for key in list(at(prefix)):
            # Refresh fragmented table proxies after structural edits.
            table = at(prefix)
            path = prefix + (key,)
            value = table[key]
            if key == "config_version":
                continue
            if path in reset_paths:
                del table[key]
                removed.append(".".join(path))
            elif isinstance(value, Mapping):
                before = len(removed)
                child_target = target.get(key, {})
                prune(child_target if isinstance(child_target, Mapping) else {}, path)
                if len(removed) > before and not at(path):
                    del at(prefix)[key]
            elif key in target and equal(
                    value if isinstance(value, bool) else value.unwrap(), target[key]):
                del table[key]
                removed.append(".".join(path))

    prune(wanted)
    backup = None
    if apply and removed:
        rendered = tomlkit.dumps(document).encode("utf-8")
        if tomllib.loads(rendered.decode("utf-8")) != document.unwrap():
            raise ValueError("rendered state failed TOML roundtrip")
        fd, name = tempfile.mkstemp(
            prefix=f"{state.name}.backup-{time.time_ns()}-", dir=state.parent)
        backup = Path(name)
        with os.fdopen(fd, "wb") as output:
            output.write(original)
            output.flush()
            os.fsync(output.fileno())
        fd, name = tempfile.mkstemp(prefix=f".{state.name}.", dir=state.parent)
        try:
            with os.fdopen(fd, "wb") as output:
                output.write(rendered)
                output.flush()
                os.fsync(output.fileno())
            if snapshot(state) != (original, identity):
                raise ValueError("state changed during reconciliation; backup retained")
            os.replace(name, state)
        finally:
            try:
                os.unlink(name)
            except OSError:
                pass  # Never remove the backup or mask a failed replacement.
    return removed, backup


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state", type=Path)
    parser.add_argument("desired", type=Path)
    parser.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    parser.add_argument("--reset", action="append", default=[], metavar="DOTTED.PATH")
    args = parser.parse_args()
    try:
        removed, backup = reconcile(args.state, args.desired, apply=args.apply, resets=args.reset)
    except (OSError, ValueError, tomlkit.exceptions.ParseError):
        parser.exit(1, "Reconciliation failed; state was not replaced. Any backup is retained.\n")
    print("Removed keys:" if args.apply else "Would remove keys:")
    for key in removed:
        print(key)
    if backup is not None:
        print(f"Backup: {backup}")


if __name__ == "__main__":
    main()
