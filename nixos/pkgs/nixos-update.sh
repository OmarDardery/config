set -euo pipefail
if [[ "${1:-}" == --help ]]; then
  printf '%s\n' 'Usage: nixos-update REPOSITORY HOST'
  exit 0
fi
if [[ $# -ne 2 || -z "$1" || ! "$2" =~ ^[A-Za-z0-9_-]+$ ]]; then
  printf '%s\n' 'Usage: nixos-update REPOSITORY HOST' >&2
  exit 2
fi
repository="path:${1#path:}"
host=$2

# Repeated button presses must not update the same lockfile concurrently.
umask 077
lock_directory="${XDG_CACHE_HOME:-$HOME/.cache}/nix-config"
mkdir -p "$lock_directory"
exec 9>"$lock_directory/update.lock"
if ! flock -n 9; then
  printf '%s\n' 'Another configuration update is already running.' >&2
  exit 1
fi

nix flake update --flake "$repository"
nix build --no-link "$repository#nixosConfigurations.$host.config.system.build.toplevel"
printf '%s\n' 'Declining leaves the updated lockfile available for inspection.'
printf '%s' 'Switch to the updated configuration? Type yes: '
if ! IFS= read -r answer || [[ "$answer" != yes ]]; then
  printf '%s\n' 'Switch cancelled; updated lockfile retained.'
  exit 1
fi
sudo nixos-rebuild switch --flake "$repository#$host"
