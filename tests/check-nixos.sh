#!/usr/bin/env bash
# Reproduce CI with temporary evaluation-only hardware.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cp -R nixos non-nixos scripts flake.nix flake.lock "$work/"
rm -f "$work/nixos/hardware-configuration.nix" "$work/nixos/local-profile.nix" "$work/nixos/local-system.json" "$work/non-nixos/local-profile.json"
cp .github/ci-hardware.nix "$work/nixos/hardware-configuration.nix"
bash -n nixos/scripts/screenshot.sh
flake="path:$work"
nix build "$flake" --no-link --no-write-lock-file
nix run "$flake" -- --help
nix run "$flake#nixos-apply" -- --help
nix flake check "$flake" --all-systems --no-build --no-write-lock-file
# Parse the shared shell helpers and native dotfile with the configured Zsh.
zsh_package=$(nix build --no-link --print-out-paths --no-write-lock-file "$flake#nixosConfigurations.nixos.config.home-manager.users.oad.programs.zsh.package^out")
"$zsh_package/bin/zsh" -n non-nixos/dotfiles/zsh/common.zsh
"$zsh_package/bin/zsh" -n non-nixos/dotfiles/zsh/.zshrc
nix eval --impure --json --expr "import ./tests/lean.nix { flake = builtins.getFlake \"$flake\"; }"
nix eval --impure --json --expr "import ./tests/features.nix { flake = builtins.getFlake \"$flake\"; }"
printf '%s\n' '{ hardwareProfile = "asus-tuf-a14"; }' > "$work/nixos/local-profile.nix"
nix eval --impure --json --expr "import ./tests/lean.nix { flake = builtins.getFlake \"$flake\"; }"
# Evaluate the NVIDIA module against the CachyOS kernel before any host activation.
nix eval --raw --no-write-lock-file "$flake#nixosConfigurations.nixos.config.hardware.nvidia.package.drvPath" >/dev/null
cat > "$work/nixos/local-profile.nix" <<EOF
{ username = "ciuser"; homeDirectory = "/srv/ciuser"; configRepo = "$work"; }
EOF
nix eval --raw "$flake#nixosConfigurations.nixos.config.home-manager.users.ciuser.home.homeDirectory" --no-write-lock-file
rm "$work/nixos/local-profile.nix"
host=$(nix eval --raw "$flake#lib.deployment.hostName" --no-write-lock-file)
profile_user=$(nix eval --raw "$flake#lib.deployment.username" --no-write-lock-file)
compositor=$(nix build --no-link --print-out-paths --no-write-lock-file "$flake#nixosConfigurations.$host.config.programs.umbriel.package")
settings=$(nix build --no-link --print-out-paths --no-write-lock-file "$flake#nixosConfigurations.$host.config.home-manager.users.$profile_user.xdg.configFile.\"umbriel/config.toml\".source")
"$compositor/bin/umbriel" config validate -c "$settings"
"$compositor/bin/umbriel" config validate -c non-nixos/dotfiles/umbriel/config.toml
ly_package=$(nix build --no-link --print-out-paths --no-write-lock-file --impure --expr "let c = (builtins.getFlake \"$flake\").nixosConfigurations.$host.config; in c.services.displayManager.ly.package.override { x11Support = c.services.displayManager.ly.x11Support; }")
"$ly_package/bin/ly" --version
ly_settings=$(nix build --no-link --print-out-paths --no-write-lock-file "$flake#nixosConfigurations.$host.config.environment.etc.\"ly/config.ini\".source")
grep -E '^animation[[:space:]]*=[[:space:]]*matrix$' "$ly_settings"
system=$(nix eval --raw "$flake#lib.deployment.system" --no-write-lock-file)
shell_package=$(nix build --no-link --print-out-paths --impure --expr "(builtins.getFlake \"$flake\").inputs.noctalia.packages.$system.default")
shell_settings=$(nix build --no-link --print-out-paths --no-write-lock-file "$flake#nixosConfigurations.$host.config.home-manager.users.$profile_user.xdg.configFile.\"noctalia/config.toml\".source")
"$shell_package/bin/noctalia" config validate "$shell_settings"
"$shell_package/bin/noctalia" config validate non-nixos/dotfiles/noctalia/config.toml
