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
  # Extract all CLI colors in one process; reject incomplete palettes.
  if colors=$(jq -er '
    [.logo.color."1", .logo.color."2", .display.color.keys,
     .display.color.title, .display.percent.color.green,
     .display.percent.color.yellow, .display.percent.color.red]
    | if all(.[]; type == "string" and test("^#[0-9a-fA-F]{6}$"))
      then .[] else error("Incomplete Fastfetch palette") end
  ' "$palette"); then
    mapfile -t colors <<< "$colors"
    # CLI overrides preserve JSONC, relative paths and custom module lists.
    "$native" \
      --logo-color-1 "${colors[0]}" \
      --logo-color-2 "${colors[1]}" \
      --color-keys "${colors[2]}" \
      --color-title "${colors[3]}" \
      --percent-color-green "${colors[4]}" \
      --percent-color-yellow "${colors[5]}" \
      --percent-color-red "${colors[6]}" "$@"
    exit
  fi
fi
"$native" "$@"
