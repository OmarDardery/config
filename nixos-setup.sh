#!/usr/bin/env bash
# Full NixOS deployment, including a fresh local generated hardware file.
set -euo pipefail
[[ -e /etc/NIXOS ]] || { printf '%s\n' 'This installer requires NixOS.' >&2; exit 1; }
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$repo_dir/nixos/bootstrap.sh" --repo-dir "$repo_dir" --activate "$@"
