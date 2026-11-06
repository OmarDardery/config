#!/usr/bin/env bash
set -euo pipefail
# Home Manager activation can have a minimal PATH. Keep the native runtime visible.
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"
if (($# == 0)); then exit 0; fi
command -v flatpak >/dev/null || {
  printf '%s\n' 'Native Flatpak is missing. Run config-apply to install host prerequisites.' >&2
  exit 1
}
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/non-nixos-config"
mkdir -p -- "$state_dir"
exec 8>"$state_dir/flatpaks.lock"
flock -n 8 || { printf '%s\n' 'Another Flatpak apply is running.' >&2; exit 1; }
for app in "$@"; do
  [[ "$app" =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+){2,}$ ]] || {
    printf 'Invalid Flatpak application ID: %s\n' "$app" >&2; exit 1;
  }
done
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for app in "$@"; do
  flatpak --user install --noninteractive --or-update flathub "$app"
done
