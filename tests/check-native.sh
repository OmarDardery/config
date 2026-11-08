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
printf '%s\n' 'Building the user-only installer...'
nix build "$NATIVE_FLAKE" --no-link --no-write-lock-file
nix run "$NATIVE_FLAKE" -- --help
