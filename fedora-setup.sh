#!/usr/bin/env bash
# Compatibility entry point; use the shared launcher on each distro.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$repo_dir/setup.sh" "$@"
