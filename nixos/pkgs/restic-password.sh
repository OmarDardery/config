# Called by the root-only systemd service with a persistent StateDirectory.
set -euo pipefail
umask 077
password="$STATE_DIRECTORY/home.password"
if [[ ! -e "$password" && ! -L "$password" ]]; then
  temporary=$(mktemp "$STATE_DIRECTORY/.home.password.XXXXXXXX")
  trap 'rm -f -- "$temporary"' EXIT
  openssl rand -base64 48 > "$temporary"
  # Publish only a complete password; never overwrite an existing key.
  ln -- "$temporary" "$password"
fi
[[ -f "$password" && ! -L "$password" && -s "$password" ]]
