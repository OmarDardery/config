"""Render deployed palettes in isolation without executing application hooks."""

import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import tomllib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", type=Path)
    parser.add_argument("umbriel", type=Path)
    parser.add_argument("wallpaper", type=Path)
    parser.add_argument("--extension", type=Path)
    args = parser.parse_args()
    settings = tomllib.loads(args.config.read_text())
    templates = settings["theme"]["templates"]["user"]
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
        prefix="noctalia-themes-", dir="/tmp/opencode"
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
            for name, template in templates.items():
                source = Path(template["input_path"])
                # The Kitty template uses an XDG token rather than a store path.
                if str(source).startswith("$XDG_CONFIG_HOME/"):
                    source = args.config.parent.parent / str(source).removeprefix(
                        "$XDG_CONFIG_HOME/"
                    )
                assert source.is_file(), source
                target = output / (name + Path(template["output_path"]).suffix)
                rendered[name] = target
                command.extend(["--render", f"{source}:{target}"])
            subprocess.run(command, check=True, capture_output=True, text=True)
            for name, target in rendered.items():
                text = target.read_text()
                assert text.strip(), name
                assert "{{colors." not in text and "<*" not in text, name
            vscode = json.loads(rendered["vscode"].read_text())
            assert vscode["colors"]["editor.background"].startswith("#")
            assert vscode["tokenColors"]
            palettes[mode] = vscode["colors"]["editor.background"]
            umbrella = tomllib.loads(rendered["umbriel"].read_text())
            assert umbrella["colors"]["tab_bar"]["urgent"].startswith("#")
            assert umbrella["colors"]["shadow"].startswith("#")
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
