#!/usr/bin/env bash
# Native Fedora applications and shared editor/dotfile configuration.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$repo_dir/nixos/native/fedora.sh" "$@"
