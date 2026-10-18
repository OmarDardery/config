"""Render deployed palettes in isolation without executing application hooks."""

import argparse
import ast
import json
from pathlib import Path
import subprocess
import tempfile
import tomllib
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", type=Path)
    parser.add_argument("umbriel", type=Path)
    parser.add_argument("wallpaper", type=Path)
    parser.add_argument("--extension", type=Path)
    parser.add_argument("--closure", type=Path, required=True)
    parser.add_argument("--kitty-template", type=Path, required=True)
    args = parser.parse_args()
    settings = tomllib.loads(args.config.read_text())
    templates = settings["theme"]["templates"]["user"]
    sources = settings["plugins"]["source"]
    names = [source["name"] for source in sources]
    assert len(names) == len(set(names)), "Duplicate plugin source names"
    assert names == ["official", "community", "nix-managed"], names
    managed = sources[-1]
    assert managed["kind"] == "path" and managed["enabled"]
    plugin_root = Path(managed["location"])
    manifests = [tomllib.loads(path.read_text()) for path in plugin_root.glob("*/plugin.toml")]
    ids = [manifest["id"] for manifest in manifests]
    assert len(ids) == len(set(ids)), "Duplicate managed plugin IDs"
    assert set(settings["plugins"]["enabled"]) <= set(ids), ids
    print("PASS: each enabled plugin resolves from the final, read-only Nix source")
    closure = set(args.closure.read_text().splitlines())
    assert str(plugin_root) in closure, "Plugin source not retained in config closure"
    for template in templates.values():
        source = Path(template["input_path"])
        assert source.is_file(), source
        assert str(Path(*source.parts[:4])) in closure, source
    print("PASS: template input sources retained in generated TOML closure")
    assert "niri" not in templates
    assert not settings["theme"]["templates"]["community_ids"]
    if args.extension:
        extension = args.extension / "share/vscode/extensions/noctalia.noctalia"
        manifest = json.loads((extension / "package.json").read_text())
        themes = manifest["contributes"]["themes"]
        assert {theme["uiTheme"] for theme in themes} == {"vs", "vs-dark"}
        for theme in themes:
            # VSCodium chooses its JSON parser from this path, not the symlink target.
            assert theme["path"].endswith(".json")
            assert (extension / theme["path"]).is_symlink()

    with tempfile.TemporaryDirectory(
        prefix="noctalia-themes-"
    ) as directory:
        root = Path(directory)
        palettes = {}
        for mode in ("dark", "light"):
            output = root / mode
            output.mkdir()
            command = [
                "noctalia",
                "theme",
                str(args.wallpaper),
                "--scheme",
                settings["theme"]["wallpaper_scheme"],
                "--both",
                "--default-mode",
                mode,
                "-o",
                str(output / "palette.json"),
            ]
            rendered = {}
            command.extend(["--render", f"{args.kitty_template}:{output / 'kitty.conf'}"])
            for name, template in templates.items():
                source = Path(template["input_path"])
                assert source.is_file(), source
                target = output / (name + Path(template["output_path"]).suffix)
                rendered[name] = target
                command.extend(["--render", f"{source}:{target}"])
            subprocess.run(command, check=True, capture_output=True, text=True)
            kitty = (output / "kitty.conf").read_text()
            assert "{{" not in kitty and "background" in kitty
            for name, target in rendered.items():
                text = target.read_text()
                assert text.strip(), name
                assert "{{colors." not in text and "<*" not in text, name
            vscode = json.loads(rendered["vscode"].read_text())
            assert vscode["colors"]["editor.background"].startswith("#")
            assert vscode["tokenColors"]
            palettes[mode] = vscode["colors"]["editor.background"]
            umbrella = tomllib.loads(rendered["umbriel"].read_text())
            assert umbrella["colors"]["border"]["focused"].startswith("#")
            assert templates["umbriel"]["input_path"].endswith("/assets/templates/umbriel/umbriel.toml")
            assert json.loads(rendered["opencode"].read_text())["theme"]
            assert json.loads(rendered["fastfetch"].read_text())["display"]["color"]
            ET.parse(rendered["libreoffice"])
            ast.parse(rendered["blender"].read_text())
            zellij_config = output / "zellij-check.kdl"
            zellij_config.write_text(rendered["zellij"].read_text() + '\ntheme "noctalia"\n')
            checked = subprocess.run(
                ["zellij", "--config", str(zellij_config), "setup", "--check"],
                check=True, capture_output=True, text=True,
            )
            assert "[CONFIG FILE]: Well defined." in checked.stdout + checked.stderr, checked.stdout + checked.stderr
            assert '--theme-color: "Matugen"' in rendered["steam"].read_text()
            tomllib.loads(rendered["yazi"].read_text())
            config = output / "umbriel-test.toml"
            config.write_text(
                "[include]\nfiles = [" + json.dumps(str(args.umbriel)) + "]\n"
                "[include.optional]\nfiles = ["
                + json.dumps(str(rendered["umbriel"]))
                + "]\n"
            )
            subprocess.run(
                ["umbriel", "config", "validate", "-c", str(config)], check=True
            )
            print(f"{mode}: {len(rendered)} templates rendered and validated")
        assert palettes["dark"] != palettes["light"], (
            "Palette mode did not change editor colors"
        )


if __name__ == "__main__":
    main()
