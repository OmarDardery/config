set -euo pipefail

usage() {
  printf '%s\n' 'Usage: config-update REPOSITORY os|home CONFIGURATION'
}

if [[ "${1:-}" == --help ]]; then
  usage
  exit 0
fi
if [[ $# -ne 3 || -z "$1" || ! "$2" =~ ^(os|home)$ || ! "$3" =~ ^[A-Za-z0-9_.@-]+$ ]]; then
  usage >&2
  exit 2
fi
repository="path:${1#path:}"
backend=$2
configuration=$3

# CLI and Noctalia share one lock for the complete update.
umask 077
lock_directory="${XDG_CACHE_HOME:-$HOME/.cache}/nix-config"
mkdir -p "$lock_directory"
exec 9>"$lock_directory/update.lock"
if ! flock -n 9; then
  printf '%s\n' 'Another configuration update is already running.' >&2
  exit 1
fi

# A pull can delete the formerly tracked hardware file. Restore it before
# evaluating/updating this NixOS checkout, but preserve existing local edits.
if [[ "$backend" == os ]]; then
  flake_directory=${repository#path:}
  bash "$flake_directory/native/copy-hardware.sh" "$(dirname -- "$flake_directory")" --if-missing
fi

printf '%s\n' 'Updating flake inputs...'
nix flake update --flake "$repository"

# nh builds before switching and shows the generation diff. Build failures stop here.
printf '%s\n' 'Building and activating the updated configuration...'
if [[ "$backend" == os ]]; then
  nh os switch --show-activation-logs --hostname "$configuration" "$repository"
else
  nix run "$repository#home-manager" -- switch --flake "$repository#$configuration"
fi

if command -v flatpak >/dev/null 2>&1; then
  printf '%s\n' 'Updating user and system Flatpaks...'
  if ! flatpak update --noninteractive --assumeyes; then
    printf '%s\n' 'Nix configuration activated, but Flatpak updates failed. Rerun flatpak update.' >&2
    exit 1
  fi
else
  printf '%s\n' 'Flatpak is not installed; skipping Flatpak updates.'
fi
printf '%s\n' 'Configuration and Flatpak updates completed.'
