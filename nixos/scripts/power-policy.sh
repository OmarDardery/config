# Laptop power policy: power profile and panel refresh follow AC, battery and games.
#   AC      → balanced,    165 Hz
#   battery → power-saver, 60 Hz
#   game    → performance, 165 Hz (while a GameMode client runs)
flag="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/power-policy-gaming"

on_ac() {
  local supply
  for supply in /sys/class/power_supply/*; do
    [[ -r "$supply/type" && -r "$supply/online" ]] || continue
    if [[ "$(<"$supply/type")" == "Mains" && "$(<"$supply/online")" == "1" ]]; then
      return 0
    fi
  done
  return 1
}

set_refresh() {
  local target_hz=$1 outputs args
  outputs=$(umbriel outputs --json 2>/dev/null) || return 0
  # Pick the advertised mode at the current resolution closest to the target.
  args=$(jq -r --argjson hz "$target_hz" '
    [.[] | select(.make == "BOE" and .model == "NE140QDM-NX7" and .enabled)] | first // empty
    | . as $o | ($o.modes[] | select(.current)) as $cur
    | [$o.modes[] | select(.width == $cur.width and .height == $cur.height)]
    | min_by(.refresh_mhz - $hz * 1000 | if . < 0 then -. else . end)
    | select(.refresh_mhz != $cur.refresh_mhz)
    | "\($o.name) \(.width)x\(.height)@\(.refresh_mhz / 1000)Hz"
  ' <<< "$outputs") || return 0
  [[ -n "$args" ]] || return 0
  read -r name mode <<< "$args"
  wlr-randr --output "$name" --mode "$mode" || printf 'power-policy: could not set %s on %s\n' "$mode" "$name" >&2
}

set_profile() {
  [[ "$(powerprofilesctl get 2>/dev/null)" == "$1" ]] && return 0
  powerprofilesctl set "$1" || printf 'power-policy: profile %s unavailable\n' "$1" >&2
}

apply() {
  if [[ -e "$flag" ]]; then
    set_profile performance; set_refresh 165
  elif on_ac; then
    set_profile balanced; set_refresh 165
  else
    set_profile power-saver; set_refresh 60
  fi
}

case "${1:-apply}" in
  apply) apply ;;
  watch)
    apply
    # Re-apply on every plug/unplug event reported by the kernel.
    udevadm monitor --udev --subsystem-match=power_supply | while read -r line; do
      [[ "$line" == *" change "* ]] || continue
      sleep 1
      apply
    done
    ;;
  game-start) touch "$flag"; apply ;;
  game-end) rm -f "$flag"; apply ;;
  *) printf 'Usage: power-policy [apply|watch|game-start|game-end]\n' >&2; exit 2 ;;
esac
