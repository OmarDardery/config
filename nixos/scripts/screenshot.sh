# Simple Wayland capture, independent of Noctalia's screenshot UI.
mode="${1:-region}"
case "$mode" in
  region|fullscreen) ;;
  *) printf 'Usage: screenshot-desktop [region|fullscreen]\n' >&2; exit 2 ;;
esac

directory="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p -- "$directory"
file="$directory/screenshot_$(date +%Y%m%d_%H%M%S_%N)-$mode.png"

if [[ "$mode" == region ]]; then
  geometry="$(slurp)" || exit 0
  [[ -n "$geometry" ]] || exit 0
  grim -g "$geometry" "$file"
else
  grim "$file"
fi
wl-copy --type image/png < "$file"
if command -v notify-send >/dev/null 2>&1; then
  notify-send -a "Screenshots" "Screenshot saved" "$file"
fi
