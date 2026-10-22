#!/usr/bin/env bash
# Compatibility dispatcher; package lists live in the distribution entry points.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck disable=SC1091
. /etc/os-release
case "$ID" in
  debian) exec bash "$repo_dir/debian-setup.sh" "$@" ;;
  fedora) exec bash "$repo_dir/fedora-setup.sh" "$@" ;;
  *) printf '%s\n' 'Use nixos-setup.sh, debian-setup.sh or fedora-setup.sh on their supported distributions.' >&2; exit 1 ;;
esac
