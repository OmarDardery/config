#!/usr/bin/env bash
set -euo pipefail

hook=$1
upstream=$2
controls_css=$3
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_CONFIG_HOME="$work/config"
profile="$XDG_CONFIG_HOME/zen/Profile with spaces"
mkdir -p "$profile/chrome" "$HOME"
: > "$profile/prefs.js"
printf '%s\n' '#custom-rule { color: red; }' > "$profile/chrome/userChrome.css"
printf '%s\n' 'user_pref("custom.setting", true);' > "$profile/user.js"

bash "$hook" "$upstream" "$controls_css"
first=$(cat "$profile/chrome/userChrome.css")
controls=$(sed -n '1s/^@import "\(.*\)";$/\1/p' "$profile/chrome/userChrome.css")
grep -q 'display: none !important' "$controls"
test "$(grep -c 'zen-window-controls.css' "$profile/chrome/userChrome.css")" -eq 1
test "$(grep -c 'zen-userChrome.css' "$profile/chrome/userChrome.css")" -eq 1
grep -q '#custom-rule { color: red; }' "$profile/chrome/userChrome.css"
grep -q 'user_pref("custom.setting", true);' "$profile/user.js"
test "$(cat "$profile/chrome/userChrome.css.noctalia-backup")" = '#custom-rule { color: red; }'

bash "$hook" "$upstream" "$controls_css"
test "$(cat "$profile/chrome/userChrome.css")" = "$first"
test "$(grep -c 'zen-window-controls.css' "$profile/chrome/userChrome.css")" -eq 1
