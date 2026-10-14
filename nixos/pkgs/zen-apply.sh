#!/usr/bin/env bash
set -euo pipefail

upstream_apply=$1
controls_css=$2
controls_import="@import \"$controls_css\";"

for root in "${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' prefs; do
        profile_dir=$(dirname "$prefs")
        for file in "$profile_dir/user.js" "$profile_dir/chrome/userChrome.css" "$profile_dir/chrome/userContent.css"; do
            if [[ -f "$file" && ! -e "$file.noctalia-backup" ]]; then
                cp -p -- "$file" "$file.noctalia-backup"
            fi
        done
    done < <(find "$root" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)
done

bash "$upstream_apply"

for root in "${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' prefs; do
        css=$(dirname "$prefs")/chrome/userChrome.css
        temp=$(mktemp "${css}.tmp.XXXXXX")
        printf '%s\n' "$controls_import" > "$temp"
        sed '/zen-window-controls\.css/d' "$css" >> "$temp"
        if ! cmp -s "$css" "$temp"; then
            cat "$temp" > "$css"
        fi
        rm -f "$temp"
    done < <(find "$root" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)
done
