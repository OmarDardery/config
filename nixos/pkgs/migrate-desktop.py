"""Desktop configuration migrations; backups contain the exact original bytes."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
import xml.etree.ElementTree as ET

from state_file import identity, replace, snapshot, sync_directory, write_bytes


def kitty_declarative(target, desired):
    """Back up unmanaged Kitty settings before Home Manager links the Nix config."""
    legacy_directory = target.parent.is_symlink()
    writable_directory(target.parent, "kitty.conf")
    if legacy_directory:
        return  # The complete directory backup already preserves the original.
    if target.is_symlink():
        if target.resolve(strict=True).is_relative_to("/nix/store"):
            return
        raise ValueError(f"{target} must not link outside the Nix store")
    original = snapshot(target, missing_ok=True)
    if original is not None:
        replace(target, original, desired.read_bytes(), preserve_mode=True)


def tablet(target, defaults):
    original = snapshot(target, missing_ok=True)
    desired = json.loads(defaults.read_bytes())
    current = json.loads(original[0]) if original is not None else desired
    expected = desired["Profiles"][0]
    profile = next((p for p in current["Profiles"] if p["Tablet"] == expected["Tablet"]), None)
    if profile is None:
        current["Profiles"].append(expected)
    else:
        area = profile.get("AbsoluteModeSettings", {})
        if area.get("Display") == {
            "Width": 1707, "Height": 1067, "X": 853.5, "Y": 533.5, "Rotation": 0
        }:
            # Only repair the old 150%-scale seed, not a user-calibrated display.
            if area.get("Tablet") == {
                "Width": 177.8, "Height": 111.095, "X": 88.9, "Y": 55.5475, "Rotation": 0
            } and area.get("LockAspectRatio") is False:
                area["Tablet"] = expected["AbsoluteModeSettings"]["Tablet"]
                area["LockAspectRatio"] = True
            area["Display"] = expected["AbsoluteModeSettings"]["Display"]

        bindings = profile.setdefault("Bindings", {})
        legacy_buttons = expected["Bindings"]["AuxButtons"][:-1] + [{
            "Path": "OpenTabletDriver.Desktop.Binding.KeyBinding",
            "Settings": [{"Property": "Key", "Value": "F6"}],
            "Enable": True,
        }]
        if "AuxButtons" not in bindings or bindings["AuxButtons"] == legacy_buttons:
            bindings["AuxButtons"] = expected["Bindings"]["AuxButtons"]
    if original is None or json.loads(original[0]) != current:
        replace(target, original, (json.dumps(current, indent=2) + "\n").encode(), preserve_mode=True)


def xournalpp_buttons(target):
    original = snapshot(target, missing_ok=True)
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True, insert_pis=True))
    root = ET.fromstring(original[0], parser=parser) if original is not None else ET.Element("settings")
    if root.tag != "settings":
        raise ValueError("Unexpected Xournal++ settings root; leaving it unchanged")
    buttons = root.find("./data[@name='buttonConfig']")
    if buttons is None:
        buttons = ET.SubElement(root, "data", name="buttonConfig")
    changed = False
    for name, tool in (("stylus", "eraser"), ("stylus2", "hand")):
        button = buttons.find(f"./data[@name='{name}']")
        if button is None:
            button = ET.SubElement(buttons, "data", name=name)
        action = button.find("./attribute[@name='tool']")
        if action is None:
            action = ET.SubElement(button, "attribute", name="tool")
        if action.get("value", "none") == "none":
            action.set("type", "string")
            action.set("value", tool)
            changed = True
    if changed:
        rendered = ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n"
        replace(target, original, rendered, preserve_mode=True)


def editor_defaults(manifest, marker):
    """Release managed files once; subsequent edits and removals belong to the user."""
    defaults = json.loads(manifest.read_bytes())
    backups = marker.parent / "backups" / marker.name
    for name, repair in defaults.get("repairs", {}).items():
        target = Path(name)
        if target.is_symlink() or any(parent.is_symlink() for parent in target.parents):
            continue  # The first migration below handles managed links.
        original = snapshot(target, missing_ok=True)
        if original is not None and hashlib.sha256(original[0]).hexdigest() == repair["sha256"]:
            backup = replace(target, original, Path(repair["source"]).read_bytes(), preserve_mode=True)
            if backup is not None:
                backups.mkdir(parents=True, exist_ok=True)
                backup.rename(backups / backup.name)
    if marker.exists():
        return
    store = Path(os.environ.get("NIX_STORE_DIR", "/nix/store")).resolve()

    def managed(path):
        return path.is_symlink() and path.resolve().is_relative_to(store)

    def backup_file(path):
        backups.mkdir(parents=True, exist_ok=True)
        fd, name = tempfile.mkstemp(prefix=f"{path.name}.", dir=backups)
        write_bytes(fd, path.read_bytes())

    def seed(source, target, force=False):
        owned = managed(target)
        if target.is_symlink() and not owned:
            return  # Preserve user-owned links, including the live Noctalia palette.
        if source.is_dir():
            if owned:
                writable_directory(target, backup_directory=backups)
            target.mkdir(parents=True, exist_ok=True)
            for child in source.iterdir():
                seed(child, target / child.name, force or owned)
            return
        if target.exists() and not owned and not force:
            target.chmod(stat.S_IMODE(target.stat().st_mode) | stat.S_IWUSR)
            return
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_symlink() and not managed(source):
            if not target.exists():
                target.symlink_to(os.readlink(source))
            return
        data = source.read_bytes()
        before = identity_link(target) if owned else snapshot(target, missing_ok=True)
        if before is not None:
            backup_file(target)
        fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.mutable-", dir=target.parent)
        try:
            write_bytes(fd, data)
            os.chmod(temporary, stat.S_IMODE(source.stat().st_mode) | 0o600)
            current = identity_link(target) if owned else snapshot(target, missing_ok=True)
            if current != before:
                raise ValueError(f"{target} changed during migration; backup retained")
            os.replace(temporary, target)
            sync_directory(target.parent)
        finally:
            Path(temporary).unlink(missing_ok=True)

    def release_links(directory):
        for path in directory.iterdir():
            if path.name == ".extensions-immutable.json":
                continue  # Home Manager removes its old bookkeeping link.
            if managed(path):
                seed(path.resolve(), path)
            if path.is_dir() and not path.is_symlink():
                release_links(path)

    for target, source in defaults["directories"].items():
        target = Path(target)
        seed(Path(source), target)
        if target.is_dir() and not target.is_symlink():
            release_links(target)
    # Codium rebuilds this index from the now-user-owned extension directories.
    if "extensionIndex" in defaults:
        index = Path(defaults["extensionIndex"])
        if index.is_file() and (not index.is_symlink() or managed(index)):
            backup_file(index)
            index.unlink()
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.touch()


def writable_tree(root):
    # Never chmod through a preserved user symlink.
    for directory, dirs, files in os.walk(root, followlinks=False):
        os.chmod(directory, stat.S_IMODE(os.stat(directory).st_mode) | 0o700)
        for name in files:
            path = Path(directory) / name
            info = path.lstat()
            if stat.S_ISREG(info.st_mode):
                os.chmod(path, stat.S_IMODE(info.st_mode) | stat.S_IWUSR)


def writable_directory(target, primary_file=None, backup_directory=None):
    """Convert the legacy directory link, preserving a backup and rollback link."""
    if not target.is_symlink():
        return
    before = identity(target.lstat())
    destination = os.readlink(target)
    if not target.is_dir():
        raise ValueError(f"{target} is a dangling or non-directory symlink")
    # Reject special files and symlink configs before touching the live path.
    config_snapshot = snapshot(target / primary_file, missing_ok=True) if primary_file else None
    transaction = Path(tempfile.mkdtemp(prefix=f".{target.name}.migration-", dir=target.parent))
    parked = transaction / "original-link"
    replacement = transaction / "replacement"
    installed = False
    try:
        backup_root = backup_directory or target.parent
        backup_root.mkdir(parents=True, exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix=f"{target.name}.backup-", dir=backup_root))
        shutil.copytree(target, backup, symlinks=True, dirs_exist_ok=True)
        backup.chmod(0o700)
        sync_tree(backup)
        sync_directory(target.parent)
        shutil.copytree(target, replacement, symlinks=True)
        writable_tree(replacement)
        if (not target.is_symlink() or identity_link(target) != (before, destination)
                or (primary_file and snapshot(target / primary_file, missing_ok=True) != config_snapshot)):
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
    {
        "kitty-declarative": kitty_declarative,
        "tablet": tablet,
        "xournalpp-buttons": xournalpp_buttons,
        "editor-defaults": editor_defaults,
    }[sys.argv[1]](
        *(Path(argument) for argument in sys.argv[2:]))
