"""Opt-in Steam hook installation with protected destinations and rollback."""
import argparse
import fnmatch
import os
from pathlib import Path
import shutil
import sys
import tempfile

DESTINATIONS = (
    "ubuntu12_32/libXtst.so.6",
    "ubuntu12_64/libXtst.so.6",
    "millennium/themes/Material-Theme",
)
MANAGED = (
    "/nix/store/*-millennium-*/lib/libmillennium_bootstrap_x86.so",
    "/nix/store/*-millennium-*/lib/libmillennium_bootstrap_hhx64.so",
    "/nix/store/*-noctalia-steam-material-*",
)


def snapshot(path):
    try:
        info = path.lstat()
    except FileNotFoundError:
        return None
    link = os.readlink(path) if path.is_symlink() else None
    return (info.st_dev, info.st_ino, info.st_mode, info.st_mtime_ns, info.st_ctime_ns, link)


def setup(root, colors, targets, *, apply=False):
    if not (root / "ubuntu12_32/steam").is_file() or not (root / "ubuntu12_64").is_dir():
        raise ValueError(f"Initialize Steam normally first; expected client at {root}")
    if not colors.is_file() or colors.stat().st_size == 0:
        raise ValueError(f"Render Noctalia steam.css before setup: {colors}")
    if not all(path.is_file() for path in targets[:2]) or not targets[2].is_dir():
        raise ValueError("Packaged Steam hook targets are missing")
    destinations = [root / name for name in DESTINATIONS]
    originals = [snapshot(path) for path in destinations]
    for path, original, pattern, target in zip(destinations, originals, MANAGED, targets):
        if original is not None and (original[-1] is None or not fnmatch.fnmatchcase(original[-1], pattern)):
            raise ValueError(f"Refusing to replace unmanaged path: {path}")
        print(f"{path} -> {target}")
    if not apply:
        print("Preview only. Run with --apply to create these links.")
        return
    changed = [i for i, original in enumerate(originals) if original is None or original[-1] != str(targets[i])]
    if not changed:
        print("Links already current. No settings were changed.")
        return
    transaction = Path(tempfile.mkdtemp(prefix=".noctalia-steam-setup-", dir=root))
    touched = []
    installed = {}
    prepared = {}
    created_directories = []
    recover = False
    try:
        for i in changed:
            staged = transaction / f"new-{i}"
            staged.symlink_to(targets[i])
            prepared[i] = snapshot(staged)
        for i in changed:
            destination = destinations[i]
            if snapshot(destination) != originals[i]:
                raise ValueError(f"{destination} changed during setup; retry")
            missing = []
            parent = destination.parent
            while not parent.exists():
                missing.append(parent)
                parent = parent.parent
            for parent in reversed(missing):
                parent.mkdir()
                created_directories.append(parent)
            if originals[i] is not None:
                os.rename(destination, transaction / f"old-{i}")
            touched.append(i)
            os.rename(transaction / f"new-{i}", destination)
            current = snapshot(destination)
            if current is None or current[:3] != prepared[i][:3] or current[-1] != str(targets[i]):
                raise ValueError(f"{destination} changed after installation; inspect retained recovery links")
            installed[i] = current
    except BaseException:
        # Restore only our own installed links; retain originals if another writer intervened.
        rollback = set(touched) | {i for i in changed if (transaction / f"old-{i}").is_symlink()}
        for i in sorted(rollback, reverse=True):
            destination = destinations[i]
            try:
                current = snapshot(destination)
                if current is not None:
                    if i not in installed or current != installed[i]:
                        recover = True
                        continue
                    destination.unlink()
                old = transaction / f"old-{i}"
                if old.is_symlink():
                    os.rename(old, destination)
            except OSError:
                recover = True
        if not recover:
            for parent in reversed(created_directories):
                try:
                    parent.rmdir()
                except OSError:
                    pass  # Leave any directory that acquired user data.
        raise
    finally:
        if recover:
            print(f"Rollback incomplete; original links retained for recovery at {transaction}", file=sys.stderr)
        else:
            shutil.rmtree(transaction)
    print("Select Material in Millennium, then Color = Matugen. No settings were changed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("colors", type=Path)
    parser.add_argument("x86", type=Path)
    parser.add_argument("x64", type=Path)
    parser.add_argument("theme", type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        setup(Path.home() / ".steam/steam", args.colors, [args.x86, args.x64, args.theme], apply=args.apply)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Steam setup failed: {error}\n")


if __name__ == "__main__":
    main()
