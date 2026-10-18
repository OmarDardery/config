#!/usr/bin/env python3
"""Remove redundant or explicitly reset Noctalia state overrides."""

import argparse
from collections.abc import Mapping
from pathlib import Path
import tomllib

import tomlkit

from state_file import replace, snapshot


def equal(left, right):
    if isinstance(left, Mapping) and isinstance(right, Mapping):
        return left.keys() == right.keys() and all(equal(left[k], right[k]) for k in left)
    if isinstance(left, list) and isinstance(right, list):
        return len(left) == len(right) and all(equal(a, b) for a, b in zip(left, right))
    if isinstance(left, bool) or isinstance(right, bool):
        return type(left) is type(right) and left == right
    return left == right


def reconcile(state, desired, *, apply=False, resets=(), managed=False):
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
            if path in reset_paths or (managed and key in target and not (
                    isinstance(value, Mapping) and isinstance(target[key], Mapping))):
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
        backup = replace(state, (original, identity), rendered)
    return removed, backup


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("state", type=Path)
    parser.add_argument("desired", type=Path)
    parser.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    parser.add_argument("--managed", action="store_true",
                        help="remove overrides for every field declared in the desired configuration")
    parser.add_argument("--reset", action="append", default=[], metavar="DOTTED.PATH")
    args = parser.parse_args()
    try:
        removed, backup = reconcile(args.state, args.desired, apply=args.apply, resets=args.reset, managed=args.managed)
    except (OSError, ValueError, tomlkit.exceptions.ParseError):
        parser.exit(1, "Reconciliation failed; inspect state and any retained backup.\n")
    print("Removed keys:" if args.apply else "Would remove keys:")
    for key in removed:
        print(key)
    if backup is not None:
        print(f"Backup: {backup}")


if __name__ == "__main__":
    main()
