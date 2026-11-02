#!/usr/bin/env bash
# Compatibility entry point; NixOS system and Home Manager.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$repo_dir/setup.sh" "$@"
