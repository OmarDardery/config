"""Desktop configuration migrations; backups contain the exact original bytes."""
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
import xml.etree.ElementTree as ET

from state_file import identity, replace, snapshot, sync_directory


def kitty_declarative(target, desired):
    """Back up unmanaged Kitty settings before Home Manager links the Nix config."""
    legacy_directory = target.parent.is_symlink()
    kitty_directory(target.parent)
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
    {
        "kitty-declarative": kitty_declarative,
        "tablet": tablet,
        "xournalpp-buttons": xournalpp_buttons,
    }[sys.argv[1]](
        *(Path(argument) for argument in sys.argv[2:]))
