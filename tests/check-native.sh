#!/usr/bin/env bash
# Run the same standalone checks locally and in CI, without activating a home.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
target_system=${1:-x86_64-linux}
[[ "$target_system" == x86_64-linux || "$target_system" == aarch64-linux ]] || {
  printf 'Unsupported test platform: %s\n' "$target_system" >&2; exit 1;
}
work=$(mktemp -d)
weston_pid=
cleanup() {
  if [[ -n "$weston_pid" ]]; then kill "$weston_pid" 2>/dev/null || true; fi
  rm -rf -- "$work"
}
trap cleanup EXIT
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
# Execute the real activation fragment, rather than repairing the host outside HM.
activation=$(nix build --no-link --print-out-paths --impure --expr 'let h = (builtins.getFlake (builtins.getEnv "NATIVE_FLAKE")).homeConfigurations.ciuser; in h.pkgs.writeShellScript "graphics-activation-smoke" ("run() { \"$@\"; }\n" + h.config.home.activation.setupHostGraphics.data)')
"$activation"
gui=$(nix build --no-link --print-out-paths --impure --expr 'let h = (builtins.getFlake (builtins.getEnv "NATIVE_FLAKE")).homeConfigurations.ciuser; in h.pkgs.symlinkJoin { name = "kitty-smoke"; paths = [ h.config.programs.kitty.package h.pkgs.xvfb-run h.pkgs.coreutils h.pkgs.weston ]; }')
# Simulate an incompatible host font configuration; Kitty must use its own.
printf '%s\n' '<fontconfig><invalid-host-rule /></fontconfig>' > "$work/host-fonts.conf"
HOME="$work/editor-home" FONTCONFIG_FILE="$work/host-fonts.conf" LIBGL_ALWAYS_SOFTWARE=1 \
  "$gui/bin/timeout" 30 "$gui/bin/xvfb-run" -a "$gui/bin/kitty" \
  --config non-nixos/dotfiles/kitty/kitty.conf \
  --override linux_display_server=x11 --override shell_integration=disabled \
  /bin/sh -c 'printf launched > "$1"' sh "$work/kitty-launched" 2>"$work/kitty-x11.log" || { cat "$work/kitty-x11.log"; exit 1; }
[[ $(cat "$work/kitty-launched") == launched ]]

printf '%s\n' 'Checking Kitty on a headless Wayland compositor...'
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -m 700 "$XDG_RUNTIME_DIR"
LIBGL_ALWAYS_SOFTWARE=1 "$gui/bin/weston" --backend=headless --renderer=pixman \
  --socket=wayland-ci --idle-time=0 --log="$work/weston.log" &
weston_pid=$!
for ((attempt=0; attempt<100; attempt++)); do
  [[ ! -S "$XDG_RUNTIME_DIR/wayland-ci" ]] || break
  if ! kill -0 "$weston_pid" 2>/dev/null; then cat "$work/weston.log"; exit 1; fi
  sleep 0.1
done
[[ -S "$XDG_RUNTIME_DIR/wayland-ci" ]]
HOME="$work/editor-home" FONTCONFIG_FILE="$work/host-fonts.conf" WAYLAND_DISPLAY=wayland-ci LIBGL_ALWAYS_SOFTWARE=1 \
  "$gui/bin/timeout" 30 "$gui/bin/kitty" \
  --config non-nixos/dotfiles/kitty/kitty.conf \
  --override linux_display_server=wayland --override shell_integration=disabled \
  /bin/sh -c 'printf launched > "$1"' sh "$work/kitty-wayland-launched" 2>"$work/kitty-wayland.log" || { cat "$work/kitty-wayland.log"; exit 1; }
[[ $(cat "$work/kitty-wayland-launched") == launched ]]
if grep -E 'Fontconfig (warning|error)' "$work/kitty-x11.log" "$work/kitty-wayland.log"; then
  exit 1
fi
