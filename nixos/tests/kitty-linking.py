"""Run pinned HM collision, migration, cleanup, and linking stages in isolated homes.

No profile installation, service reload, or real activation is executed.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

fixtures = json.loads(Path(sys.argv[1]).read_text())


def generation(root, name):
    path = root / ("generation-" + name)
    path.mkdir(exist_ok=True)
    if not (path / "home-files").is_symlink():
        (path / "home-files").symlink_to(fixtures[name]["files"])
    return path


def activate(root, home, name, old=None, *, backup=False, dry=False, success=True):
    fixture = fixtures[name]
    new = generation(root, name)
    environment = {**os.environ, "HOME": str(home), "HOME_MANAGER_BACKUP_EXT": "bak" if backup else "",
                   "HOME_MANAGER_BACKUP_COMMAND": "", "VERBOSE_ARG": ""}
    environment.pop("DRY_RUN", None)
    environment.pop("HOME_MANAGER_BACKUP_OVERWRITE", None)
    environment.pop("oldGenPath", None)
    if dry:
        environment["DRY_RUN"] = "1"
    # Use the actual HM library, including its dry-run-aware run function.
    script = 'set -euo pipefail\n' + fixture["init"] + '\nexport VERBOSE_ARG=""\n'
    script += 'newGenPath=' + shell_quote(str(new)) + '\n'
    if old:
        script += 'oldGenPath=' + shell_quote(str(root / ("generation-" + old))) + '\n'
    for stage in ("checkLinkTargets", "kittyDirectoryMigration", "linkGeneration", "kittyWritableConfig"):
        script += fixture["activation"][stage].replace(fixture["homeDirectory"], str(home)) + '\n'
    result = subprocess.run(["bash", "-c", script], env=environment, capture_output=True, text=True)
    assert (result.returncode == 0) == success, (name, old, result.stdout, result.stderr)
    return result


def shell_quote(value):
    import shlex
    return shlex.quote(value)


def kitty_path(home):
    return home / 'config "custom"/kitty'


def tree_snapshot(home):
    return sorted((str(path.relative_to(home)), "link", os.readlink(path)) if path.is_symlink()
                  else (str(path.relative_to(home)), "directory", "") if path.is_dir()
                  else (str(path.relative_to(home)), "file", path.read_bytes())
                  for path in home.rglob("*"))


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    for backup in (False, True):
        case = root / ("backup" if backup else "standalone")
        case.mkdir()
        home = case / 'home "quoted" $literal'
        home.mkdir()
        # Fresh installation and later edits survive repeated activation.
        activate(case, home, "current", backup=backup)
        kitty = kitty_path(home)
        assert (kitty / "kitty.conf").is_file() and not (kitty / "kitty.conf").is_symlink()
        assert (kitty / "themes").is_dir()
        (kitty / "kitty.conf").write_text("font_size 29\ninclude themes/noctalia.conf\n")
        (kitty / "user.conf").write_bytes(b"custom settings")
        activate(case, home, "current", "current", backup=backup)
        assert "29" in (kitty / "kitty.conf").read_text()
        assert (kitty / "user.conf").read_bytes() == b"custom settings"
        before = tree_snapshot(home)
        activate(case, home, "current", "current", backup=backup, dry=True)
        assert tree_snapshot(home) == before

        # A managed desktop-file collision fails before migration or linking.
        collision = case / 'collision "home"'
        collision.mkdir()
        conflicting = collision / 'config "custom"/autostart/org.kde.kdeconnect.daemon.desktop'
        conflicting.parent.mkdir(parents=True)
        conflicting.write_bytes(b"user-owned launcher")
        before = tree_snapshot(collision)
        activate(case, collision, "current", success=False)
        assert tree_snapshot(collision) == before

        # Convert the historical directory link and preserve every existing file.
        legacy = case / 'legacy "home" $literal'
        legacy.mkdir()
        activate(case, legacy, "legacy")
        legacy_kitty = kitty_path(legacy)
        assert legacy_kitty.is_symlink()
        original = (legacy_kitty / "kitty.conf").read_bytes()
        before = tree_snapshot(legacy)
        activate(case, legacy, "current", "legacy", backup=backup, dry=True)
        assert tree_snapshot(legacy) == before
        activate(case, legacy, "current", "legacy", backup=backup)
        assert not legacy_kitty.is_symlink()
        assert (legacy_kitty / "kitty.conf").is_file()
        assert "font_size 31" in (legacy_kitty / "kitty.conf").read_text()
        assert "include themes/noctalia.conf" in (legacy_kitty / "kitty.conf").read_text()
        backups = list(legacy_kitty.parent.glob("kitty.backup-*"))
        assert len(backups) == 1
        assert (backups[0] / "kitty.conf").read_bytes() == original
        for name in ("legacy-image.png", "custom.conf"):
            assert (legacy_kitty / name).read_bytes() == (backups[0] / name).read_bytes()
            assert not (legacy_kitty / name).is_symlink()
        (legacy_kitty / "kitty.conf").write_text("font_size 33\ninclude themes/noctalia.conf\n")
        activate(case, legacy, "current", "current", backup=backup)
        assert "33" in (legacy_kitty / "kitty.conf").read_text()
        assert len(list(legacy_kitty.parent.glob("kitty.backup-*"))) == 1
        assert not list(legacy_kitty.parent.glob(".kitty.migration-*"))
print("PASS: HM collision checks, fresh setup, legacy backups, settings preservation and dry runs")
