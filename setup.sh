#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec nix --extra-experimental-features 'nix-command flakes' run "path:$repo_dir" -- --repo-dir "$repo_dir" "$@"
