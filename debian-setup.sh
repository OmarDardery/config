#!/usr/bin/env bash
# Compatibility entry point: the distribution owns its desktop and services.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ! -f "$repo_dir/nixos/bootstrap.sh" ]]; then
  printf '%s\n' \
    'Use this entry point from a config repository checkout.' \
    'Clone https://github.com/OmarDardery/config.git, then run bash nixos/bootstrap.sh.' \
    'The old privileged Debian desktop installer has been retired.' >&2
  exit 1
fi
exec bash "$repo_dir/nixos/bootstrap.sh" --repo-dir "$repo_dir" "$@"
