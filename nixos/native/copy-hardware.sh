#!/usr/bin/env bash
# Called by bootstrap before any NixOS evaluation; never modifies /etc/nixos.
set -euo pipefail
repo=${1:?Repository directory required}
source_file=/etc/nixos/hardware-configuration.nix
target="$repo/nixos/hardware-configuration.nix"
[[ -f "$source_file" && -s "$source_file" ]] || {
  printf '%s\n' "Missing $source_file; run sudo nixos-generate-config first." >&2
  exit 1
}
if [[ -f "$target" ]] && cmp -s -- "$source_file" "$target"; then
  exit 0
fi
if [[ -e "$target" || -L "$target" ]]; then
  backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/config-backups"
  mkdir -p -- "$backup_dir"
  backup=$(mktemp "$backup_dir/hardware-configuration.XXXXXXXX.nix")
  cp -L -- "$target" "$backup"
  printf 'Previous hardware configuration saved to %s\n' "$backup"
fi
# Replace a stale file or symlink without writing through it.
temporary=$(mktemp "$repo/nixos/.hardware-configuration.XXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
cat -- "$source_file" > "$temporary"
chmod 644 "$temporary"
mv -fT -- "$temporary" "$target"
printf 'Copied %s to %s\n' "$source_file" "$target"
