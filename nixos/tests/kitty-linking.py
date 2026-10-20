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
    for stage in ("checkLinkTargets", "kittyDeclarativeConfig", "linkGeneration", "noctaliaWallpaperSamples"):
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


def parse_kitty(path, home, *, success=True):
    # Kitty's +runpy uses optimized Python, so assertions in that code are skipped.
    code = '''
import json, sys
from kitty.config import load_config
bad = []
opts = load_config(sys.argv[1], accumulate_bad_lines=bad)
if bad:
    raise ValueError(f"Kitty configuration errors: {bad}")
print(json.dumps({"font_size": opts.font_size,
                  "background": [opts.background.red, opts.background.green, opts.background.blue]}))
'''
    result = subprocess.run([
        fixtures["current"]["kitty"], "+runpy", code, str(path),
    ], capture_output=True, text=True, env={
        **os.environ, "HOME": str(home),
        "XDG_CONFIG_HOME": str(kitty_path(home).parent),
        "XDG_CACHE_HOME": str(home / "cache"),
        "XDG_DATA_HOME": str(home / "data"),
        "XDG_STATE_HOME": str(home / 'state "custom"'),
    })
    if success:
        assert result.returncode == 0, (result.stdout, result.stderr)
        return json.loads(result.stdout)
    assert result.returncode != 0, "The parser check accepted an invalid configuration"
    assert "Kitty configuration errors" in result.stderr, result.stderr


def check_palette(config, home):
    # Relocate the generated fixture's state path into the disposable home.
    palette = home / 'state "custom"/noctalia/theme/kitty.conf'
    declared_palette = str(Path(fixtures["current"]["stateHome"]) / "noctalia/theme/kitty.conf")
    contents = config.read_text()
    assert f"include {declared_palette}" in contents
    rendered = home / "parser-kitty.conf"
    rendered.write_text(contents.replace(declared_palette, str(palette)))

    missing = parse_kitty(rendered, home)
    assert missing["font_size"] == 14
    palette.parent.mkdir(parents=True)
    for color, rgb in (("#123456", [18, 52, 86]), ("#abcdef", [171, 205, 239])):
        palette.write_text(f"background {color}\n")
        loaded = parse_kitty(rendered, home)
        assert loaded["background"] == rgb, loaded
        assert loaded["font_size"] == 14
    palette.unlink()
    assert parse_kitty(rendered, home) == missing

    # Negative control: the exact absolute globinclude regression must fail.
    invalid = home / "invalid-kitty.conf"
    invalid.write_text(f"globinclude {palette}\n")
    parse_kitty(invalid, home, success=False)


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
        assert (kitty / "kitty.conf").is_file() and (kitty / "kitty.conf").is_symlink()
        check_palette(kitty / "kitty.conf", home)
        (kitty / "user.conf").write_bytes(b"custom settings")
        activate(case, home, "current", "current", backup=backup)
        assert "font_size 14" in (kitty / "kitty.conf").read_text()
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
        assert (legacy / 'Pictures/Wallpapers').is_symlink()
        original = (legacy_kitty / "kitty.conf").read_bytes()
        before = tree_snapshot(legacy)
        activate(case, legacy, "current", "legacy", backup=backup, dry=True)
        assert tree_snapshot(legacy) == before
        activate(case, legacy, "current", "legacy", backup=backup)
        wallpapers = legacy / 'Pictures/Wallpapers'
        assert wallpapers.is_dir() and not wallpapers.is_symlink()
        assert (wallpapers / 'dark-mountain.jpg').is_file()
        personal = wallpapers / 'my-wallpaper.png'
        personal.write_bytes(b'personal wallpaper')
        assert not legacy_kitty.is_symlink()
        assert (legacy_kitty / "kitty.conf").is_file()
        assert (legacy_kitty / "kitty.conf").is_symlink()
        assert "font_size 14" in (legacy_kitty / "kitty.conf").read_text()
        assert "include " in (legacy_kitty / "kitty.conf").read_text()
        backups = list(legacy_kitty.parent.glob("kitty.backup-*"))
        assert len(backups) == 1
        assert (backups[0] / "kitty.conf").read_bytes() == original
        for name in ("legacy-image.png", "custom.conf"):
            assert (legacy_kitty / name).read_bytes() == (backups[0] / name).read_bytes()
            assert not (legacy_kitty / name).is_symlink()
        activate(case, legacy, "current", "current", backup=backup)
        assert personal.read_bytes() == b'personal wallpaper'
        assert "font_size 14" in (legacy_kitty / "kitty.conf").read_text()
        assert len(list(legacy_kitty.parent.glob("kitty.backup-*"))) == 1
        assert not list(legacy_kitty.parent.glob(".kitty.migration-*"))
print("PASS: Kitty parsing, palette loading/fallback, HM linking, migration backups, file preservation and dry runs")
