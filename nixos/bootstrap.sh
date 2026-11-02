#!/usr/bin/env bash
# Compatibility entry point.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
exec bash "$repo_dir/setup.sh" "$@"
