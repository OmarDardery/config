#!/usr/bin/env bash
# Run the same standalone checks locally and in CI, without activating a home.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
target_system=${1:-x86_64-linux}
[[ "$target_system" == x86_64-linux || "$target_system" == aarch64-linux ]] || {
  printf 'Unsupported test platform: %s\n' "$target_system" >&2; exit 1;
}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cp -R non-nixos/. "$work/"
rm -f "$work/local-profile.json"
jq -n --arg system "$target_system" '{username:"ciuser",homeDirectory:"/srv/ci home",system:$system,configHome:"/srv/ci home/settings",dataHome:"/srv/ci home/data",zshHome:"/srv/ci home/shell"}' > "$work/local-profile.json"
export NATIVE_FLAKE="path:$work"
printf 'Evaluating desktop and recovery mode for %s...\n' "$target_system"
nix eval --impure --json --expr 'import ./tests/native.nix { flake = builtins.getFlake (builtins.getEnv "NATIVE_FLAKE"); }'
nix flake check "$NATIVE_FLAKE" --all-systems --no-build --no-write-lock-file
if [[ "$target_system" != x86_64-linux || $(uname -m) != x86_64 ]]; then
  printf '%s\n' 'Evaluation passed; runtime smoke checks require an x86_64 host and target.'
  exit 0
fi
printf '%s\n' 'Building installers and checking editor binaries...'
nix build "$NATIVE_FLAKE" --no-link --no-write-lock-file
nix run "$NATIVE_FLAKE" -- --help
nix build "$NATIVE_FLAKE#homeConfigurations.ciuser.config.desktop.flatpak.installer" \
  "$NATIVE_FLAKE#homeConfigurations.ciuser.config.targets.genericLinux.gpu.setupPackage" --no-link --no-write-lock-file
editors=$(nix build --no-link --print-out-paths --impure --expr 'let h = (builtins.getFlake (builtins.getEnv "NATIVE_FLAKE")).homeConfigurations.ciuser; in h.pkgs.symlinkJoin { name = "editor-smoke"; paths = [ h.config.programs.neovim.finalPackage h.config.programs.vscodium.package ]; }')
mkdir -p "$work/editor-home"
HOME="$work/editor-home" "$editors/bin/nvim" --clean --headless '+quit'
HOME="$work/editor-home" "$editors/bin/codium" --version

printf '%s\n' 'Checking an actual Kitty window with software rendering...'
graphics=$(nix eval --json "$NATIVE_FLAKE#lib.hostRequirements.graphics")
bash non-nixos/graphics.sh "$(jq -r .drivers <<< "$graphics")" "$(jq -r .setup <<< "$graphics")"
gui=$(nix build --no-link --print-out-paths --impure --expr 'let h = (builtins.getFlake (builtins.getEnv "NATIVE_FLAKE")).homeConfigurations.ciuser; in h.pkgs.symlinkJoin { name = "kitty-smoke"; paths = [ h.pkgs.kitty h.pkgs.xvfb-run h.pkgs.coreutils ]; }')
HOME="$work/editor-home" LIBGL_ALWAYS_SOFTWARE=1 \
  "$gui/bin/timeout" 30 "$gui/bin/xvfb-run" -a "$gui/bin/kitty" \
  --config non-nixos/dotfiles/kitty/kitty.conf \
  --override linux_display_server=x11 --override shell_integration=disabled \
  /bin/sh -c 'printf launched > "$1"' sh "$work/kitty-launched"
[[ $(cat "$work/kitty-launched") == launched ]]
