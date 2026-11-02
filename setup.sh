#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ -e /etc/NIXOS ]]; then flake="path:$repo_dir"; else flake="path:$repo_dir/non-nixos"; fi
exec nix --extra-experimental-features 'nix-command flakes' run "$flake" -- --repo-dir "$repo_dir" "$@"
