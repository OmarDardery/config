#!/usr/bin/env bash
# Compatibility entry point: the distribution owns its desktop and services.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ! -f "$repo_dir/nixos/bootstrap.sh" ]]; then
  repo_dir="${HOME:?HOME must be set}/config"
fi
if [[ ! -f "$repo_dir/nixos/bootstrap.sh" ]]; then
  printf '%s\n' \
    'No configuration checkout found beside this script or at ~/config.' \
    'Run: git clone https://github.com/OmarDardery/config.git ~/config' \
    'Then: bash ~/config/nixos/bootstrap.sh --activate' \
    'The old privileged Debian desktop installer has been retired.' >&2
  exit 1
fi
exec bash "$repo_dir/nixos/bootstrap.sh" --repo-dir "$repo_dir" "$@"
