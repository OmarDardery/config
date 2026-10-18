"""Exercise the generated Bat seed/cache hooks in an isolated writable home."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

fixture = json.loads(Path(sys.argv[1]).read_text())
with tempfile.TemporaryDirectory() as directory:
    home = Path(directory) / 'home "quoted" $literal'
    home.mkdir()
    config = home / 'config "custom"'
    cache = home / 'cache "custom"'
    replacements = {
        fixture["cacheHome"]: str(cache),
        fixture["configHome"]: str(config),
        fixture["homeDirectory"]: str(home),
    }
    script = 'set -euo pipefail\n' + fixture["init"] + '\n' + fixture["seed"] + '\n' + fixture["cache"]
    for original, replacement in replacements.items():
        script = script.replace(original, replacement)
    environment = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(config), "XDG_CACHE_HOME": str(cache)}
    environment.pop("DRY_RUN", None)
    # No palette or cache is created by the actual dry-run-aware HM hooks.
    subprocess.run(["bash", "-c", script], env={**environment, "DRY_RUN": "1"}, check=True)
    assert not list(home.iterdir())
    subprocess.run(["bash", "-c", script], env=environment, check=True)
    theme = config / "bat/themes/noctalia.tmTheme"
    assert theme.is_file() and not theme.is_symlink()
    assert "{{" not in theme.read_text()
    for relative in ["opencode/themes/noctalia.json",
                     "yazi/flavors/noctalia.yazi/flavor.toml"]:
        assert (config / relative).is_file(), relative
    assert json.loads(Path(fixture["opencodeTui"]).read_text())["theme"] == "noctalia"
    bat_config = config / "bat/config"
    bat_config.write_text('--theme="noctalia"\n')
    environment["BAT_CONFIG_PATH"] = str(bat_config)
    environment.pop("BAT_THEME", None)
    bat = str(Path(fixture["bat"]) / "bin/bat")

    def check_bat():
        result = subprocess.run([bat, "--color=always", "--paging=never", str(bat_config)], env=environment, capture_output=True, text=True, check=True)
        assert not result.stderr, result.stderr
        result = subprocess.run([bat, "--list-themes", "--color=never"], env=environment, capture_output=True, text=True, check=True)
        assert "noctalia" in result.stdout.splitlines()

    check_bat()
    original = theme.read_bytes() + b"\n<!-- user retained -->\n"
    theme.write_bytes(original)
    subprocess.run(["bash", "-c", script], env=environment, check=True)
    assert theme.read_bytes() == original
    check_bat()
    shutil.rmtree(cache)
    subprocess.run(["bash", "-c", script], env=environment, check=True)
    assert theme.read_bytes() == original
    check_bat()
print("PASS: editor/file-browser palettes, Bat cache, preservation and dry run")
