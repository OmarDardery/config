set -euo pipefail
if [[ $# -ne 2 ]]; then
  printf '%s\n' 'Usage: nixos-update REPOSITORY HOST' >&2
  exit 2
fi
repository="path:${1#path:}"
host=$2
nix flake update --flake "$repository"
nix build --no-link "$repository#nixosConfigurations.$host.config.system.build.toplevel"
printf '%s\n' 'Declining leaves the updated lockfile available for inspection.'
printf '%s' 'Switch to the updated configuration? Type yes: '
if ! IFS= read -r answer || [[ "$answer" != yes ]]; then
  printf '%s\n' 'Switch cancelled; updated lockfile retained.'
  exit 1
fi
sudo nixos-rebuild switch --flake "$repository#$host"
