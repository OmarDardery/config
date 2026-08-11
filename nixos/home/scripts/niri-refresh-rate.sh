# Match the internal panel's refresh rate to the active power profile.
#
# Wrapped by pkgs.writeShellApplication, which supplies the shebang, the
# `set -euo pipefail` and the PATH. Keeping it as a plain .sh file rather than a
# string inside the .nix means no Nix escaping to read around, and shellcheck
# runs over it on every rebuild.
#
# Why this exists: the AMD iGPU parks at its lowest DPM level (800 MHz core,
# 400 MHz memory, out of 2700/937) whenever power-profiles-daemon is not asking
# for more. At 165 Hz a frame is due every 6 ms, which is less time than the SMU
# takes to ramp up, so a burst of compositing work lands after its deadline and
# niri composites the regions it did not redraw as empty. Lowering the refresh
# rate widens the frame budget instead of fighting the governor.

# Refresh rate to run at, per profile. "max" is the fastest rate the panel
# advertises, so this file does not need to know which laptop it is on.
rate_for() {
    case "$1" in
    performance) echo max ;;
    balanced) echo 100 ;;
    power-saver) echo 60 ;;
    *) echo max ;;
    esac
}

# Always `custom-mode`, never `mode`. `mode` needs the refresh rate to match an
# advertised one to three decimals, and silently falls back to the preferred
# mode when it does not: asking this panel for "60" when it advertises 60.002
# leaves you at 165 Hz with no error and exit status 0.
apply() {
    local profile=$1 outputs panel size rate

    outputs=$(niri msg --json outputs) || return 0

    # Look the panel up every time rather than hardcoding it: the connector
    # flips between eDP-1 and eDP-2 across boots depending on whether amdgpu or
    # nvidia probes first.
    panel=$(jq -r 'first(keys[] | select(startswith("eDP"))) // empty' <<<"$outputs")
    if [ -z "$panel" ]; then
        echo "no internal panel connected, nothing to do"
        return 0
    fi

    # Native resolution is whatever the preferred mode uses.
    size=$(jq -r --arg p "$panel" \
        '.[$p].modes as $m | (first($m[] | select(.is_preferred)) // $m[0])
         | "\(.width)x\(.height)"' <<<"$outputs")

    rate=$(rate_for "$profile")
    if [ "$rate" = max ]; then
        # refresh_rate is in millihertz.
        rate=$(jq -r --arg p "$panel" --arg s "$size" \
            '[.[$p].modes[] | select("\(.width)x\(.height)" == $s) | .refresh_rate]
             | max / 1000 | floor' <<<"$outputs")
    fi

    echo "power profile $profile -> $panel $size@$rate"
    niri msg output "$panel" custom-mode "$size@$rate" || echo "niri rejected $size@$rate"
}

profile=$(powerprofilesctl get)
apply "$profile"

# power-profiles-daemon has no "watch" command and no hook mechanism -- its
# actions are compiled-in plugins, and `configure-action` only enables and
# disables those -- so listen for the property change on the bus instead.
#
# gdbus rather than dbus-monitor: dbus-monitor asks to see every message on the
# bus, which an ordinary user is not allowed to do, so it prints an
# AccessDenied error and falls back to eavesdropping. Subscribing to one
# object's signals needs no privileges at all. ppd exports this under two bus
# names and both emit, so binding to one gives one wake-up per change.
#
# The signal body is not parsed; a signal is just a cue to re-read the profile,
# and the comparison below stops the two header lines gdbus prints at startup
# from causing a pointless modeset.
gdbus monitor --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles |
    while read -r _; do
        current=$(powerprofilesctl get)
        if [ "$current" != "$profile" ]; then
            profile=$current
            apply "$profile"
        fi
    done
