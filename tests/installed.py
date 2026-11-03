#!/usr/bin/env python3
"""Evaluate installed bootloader capture and round-trip it through NixOS modules."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def evaluate(expression):
    result = subprocess.check_output([
        "nix", "--extra-experimental-features", "nix-command flakes", "eval",
        "--impure", "--json", "--no-write-lock-file", "--expr", expression
    ], text=True, cwd=ROOT)
    return json.loads(result)

with tempfile.TemporaryDirectory() as temp:
    fixture = Path(temp)
    for loader in ("systemd-boot", "grub"):
        (fixture / "configuration.nix").write_text('''
        { ... }: {
          system.stateVersion = "25.05";
          boot.loader.LOADER.enable = true;
          boot.loader.grub.device = "/dev/test";
          boot.loader.efi.efiSysMountPoint = "/efi";
        }
        '''.replace("LOADER", loader))
        # Env avoids embedding arbitrary paths in a Nix string expression.
        os.environ["TEST_CONFIG_FLAKE"] = f"path:{ROOT}"
        os.environ["TEST_INSTALLED_DIRECTORY"] = str(fixture)
        captured = evaluate('''
          let f = builtins.getFlake (builtins.getEnv "TEST_CONFIG_FLAKE");
          in import ./scripts/installed-system.nix {
            nixpkgs = f.inputs.nixpkgs; username = "tester"; hostName = "fixture";
            configurationDirectory = builtins.toPath (builtins.getEnv "TEST_INSTALLED_DIRECTORY");
          }
        ''')
        assert captured["stateVersion"] == "25.05"
        assert captured["bootLoader"][loader]["enable"]
        (fixture / "captured.json").write_text(json.dumps(captured))
        result = evaluate('''
          let f = builtins.getFlake (builtins.getEnv "TEST_CONFIG_FLAKE");
              captured = builtins.fromJSON (builtins.readFile
                (builtins.getEnv "TEST_INSTALLED_DIRECTORY" + "/captured.json"));
              c = (f.inputs.nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [{
                  system.stateVersion = captured.stateVersion;
                  boot.loader = captured.bootLoader;
                }];
              }).config;
          in { stateVersion = c.system.stateVersion; loader = c.boot.loader; }
        '''.replace('loader = c.boot.loader;', '''loader = {
            systemd = c.boot.loader.systemd-boot.enable;
            grub = c.boot.loader.grub.enable;
            targets = c.boot.loader.grub.mirroredBoots;
            efi = c.boot.loader.efi.efiSysMountPoint;
          };'''))
        assert result["stateVersion"] == "25.05"
        assert result["loader"]["efi"] == "/efi"
        if loader == "grub":
            assert len(result["loader"]["targets"]) == 1, result
            assert result["loader"]["targets"][0]["devices"] == ["/dev/test"], result
        print(f"Installed {loader}: state version and boot target round-trip passed")
