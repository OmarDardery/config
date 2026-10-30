# Called by Noctalia's power hooks, not a polling service.
set -euo pipefail
mode=${1:-detect}
refresh=${2:-}
: "${XDG_RUNTIME_DIR:?Run this inside the graphical session}"
umask 077
state_dir="$XDG_RUNTIME_DIR/desktop-power"
mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock 9
# Read the current source after acquiring the lock so queued hooks cannot apply
# an old plug/unplug event after a newer one.
if [[ "$mode" == detect ]]; then
  mode=battery
  battery_present=false
  for supply in /sys/class/power_supply/*; do
    [[ -r "$supply/type" ]] || continue
    [[ $(<"$supply/type") == Battery ]] && battery_present=true
    if [[ -r "$supply/online" && $(<"$supply/online") == 1 ]]; then mode=ac; fi
  done
  [[ "$battery_present" == true ]] || exit 0
fi
case "$mode" in
  battery) profile=power-saver; lock=300; screen=360; suspend=true ;;
  ac) profile=balanced; lock=600; screen=900; suspend=false ;;
  *) printf '%s\n' 'Usage: desktop-power [detect|ac|battery] [--refresh]' >&2; exit 2 ;;
esac
if [[ "$refresh" != --refresh && -r "$state_dir/source" && $(<"$state_dir/source") == "$mode" ]]; then
  exit 0
fi
# Manual profile changes remain in effect until the next power-source change.
noctalia msg power-set "$profile" >/dev/null
noctalia msg config-set idle.behavior.lock.timeout "$lock" >/dev/null
noctalia msg config-set idle.behavior.screen-off.timeout "$screen" >/dev/null
noctalia msg config-set idle.behavior.suspend.enabled "$suspend" >/dev/null
printf '%s\n' "$mode" > "$state_dir/source"
