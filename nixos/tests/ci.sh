#!/usr/bin/env bash
# Evaluate the real flake with disposable, explicitly non-deployable hardware.
set -euo pipefail
source_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cp -R -- "$source_directory" "$work/nixos"
cp -- "$source_directory/tests/fixtures/ci-hardware.nix" "$work/nixos/hardware-configuration.nix"
flake="path:$work/nixos"
system=$(nix eval --raw "$flake#lib.deployment.system" --no-write-lock-file)

nix flake check "$flake" --no-build --no-write-lock-file
checks=(
  portability
  ci-isolation
  restic-password
  dotfile-syntax
  config-update
  flatpak-font-cache
  desktop-migrations
  reconciliation
  office-convert
  native-setup
  bootstrap
  theme-rendering
)
outputs=()
for check in "${checks[@]}"; do
  outputs+=("$flake#checks.$system.$check")
done
nix build --no-link --no-write-lock-file --print-build-logs "${outputs[@]}"
