#!/usr/bin/env bash
# Keep the account shell on the stable user profile, not a collectable store path.
set -euo pipefail
username=${1:?expected account name}
shell=${2:?expected stable Zsh path}
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
[[ "$username" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || die 'invalid account name'
[[ "$shell" == /* && "$shell" != *:* && "$shell" != *$'\n'* ]] || die 'invalid login shell path'
[[ -x "$shell" ]] || die "Zsh is not available at $shell; profile installation must finish first"
record=$(getent passwd "$username") || die "account does not exist: $username"
current=${record##*:}
if [[ "$current" == "$shell" ]] && grep -Fqx -- "$shell" /etc/shells; then exit 0; fi
if [[ $(id -u) != 0 ]]; then
  [[ $(id -un) == "$username" ]] || die 'run as the account being configured'
  command -v sudo >/dev/null || die 'setting the login shell requires sudo'
  printf '%s\n' 'Registering Zsh and selecting it as your login shell (sudo required).'
  exec sudo -- "$BASH" "$0" "$username" "$shell"
fi
command -v usermod >/dev/null || die 'install your distro account-management tools (usermod), then reapply'
if ! grep -Fqx -- "$shell" /etc/shells; then printf '\n%s\n' "$shell" >> /etc/shells; fi
if [[ "$current" != "$shell" ]]; then usermod --shell "$shell" "$username"; fi
