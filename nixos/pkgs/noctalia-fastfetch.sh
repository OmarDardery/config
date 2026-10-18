# Use the upstream merger on a disposable copy, never on the user's config.
set -euo pipefail
native=$1
apply=$2
config_home=$3
shift 3
for argument in "$@"; do
  case "$argument" in
    -c|--config|--config=*) exec "$native" "$@" ;;
  esac
done
theme="$config_home/fastfetch/themes/noctalia.jsonc"
if [[ ! -s "$theme" ]]; then
  exec "$native" "$@"
fi
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/fastfetch/themes"
cp -- "$theme" "$work/fastfetch/themes/noctalia.jsonc"
printf '{}\n' > "$work/fastfetch/config.jsonc"
if XDG_CONFIG_HOME="$work" bash "$apply"; then
  palette="$work/fastfetch/config.jsonc"
  # Native CLI overrides preserve JSONC, relative paths and custom module lists.
  "$native" \
    --logo-color-1 "$(jq -r '.logo.color."1"' "$palette")" \
    --logo-color-2 "$(jq -r '.logo.color."2"' "$palette")" \
    --color-keys "$(jq -r '.display.color.keys' "$palette")" \
    --color-title "$(jq -r '.display.color.title' "$palette")" \
    --percent-color-green "$(jq -r '.display.percent.color.green' "$palette")" \
    --percent-color-yellow "$(jq -r '.display.percent.color.yellow' "$palette")" \
    --percent-color-red "$(jq -r '.display.percent.color.red' "$palette")" "$@"
else
  "$native" "$@"
fi
