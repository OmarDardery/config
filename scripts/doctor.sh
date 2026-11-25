#!/usr/bin/env bash
# Read-only post-boot checks for the NixOS desktop.
set -euo pipefail
printf 'Kernel: '; uname -r
printf 'Session: %s\n' "${XDG_SESSION_TYPE:-unknown}"
if command -v powerprofilesctl >/dev/null 2>&1; then
  printf 'Power profile: '; powerprofilesctl get || true
fi
if command -v nvidia-smi >/dev/null 2>&1; then
  printf '\nNVIDIA driver and GPU:\n'
  nvidia-smi --query-gpu=driver_version,name,pstate --format=csv,noheader || true
fi
if command -v lsmod >/dev/null 2>&1; then
  if lsmod | grep -q '^nvidia '; then
    printf 'NVIDIA kernel module: loaded\n'
  else
    printf 'NVIDIA kernel module: not loaded (normal on some offload configurations)\n'
  fi
fi
for battery in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
  if [[ -r "$battery" ]]; then
    printf 'Battery threshold (%s): %s%%\n' "${battery%/*}" "$(cat "$battery")"
  fi
done
printf '\nBattery:\n'
for supply in /sys/class/power_supply/*; do
  [[ -r "$supply/type" ]] || continue
  case "$(cat "$supply/type")" in
    Mains) printf '  AC (%s): %s\n' "${supply##*/}" "$([[ "$(cat "$supply/online")" == 1 ]] && echo online || echo offline)" ;;
    Battery)
      name=${supply##*/}
      watts=""
      if [[ -r "$supply/power_now" ]]; then
        watts=$(( $(cat "$supply/power_now") / 100000 ))
      elif [[ -r "$supply/current_now" && -r "$supply/voltage_now" ]]; then
        watts=$(( $(cat "$supply/current_now") * $(cat "$supply/voltage_now") / 100000000000 ))
      fi
      printf '  %s: %s%%, %s' "$name" "$(cat "$supply/capacity" 2>/dev/null || echo '?')" "$(cat "$supply/status" 2>/dev/null || echo '?')"
      [[ -n "$watts" ]] && printf ', draw %d.%d W' "$(( watts / 10 ))" "$(( watts % 10 ))"
      printf '\n'
      ;;
  esac
done
for gpu in /sys/bus/pci/drivers/nvidia/0000:*; do
  [[ -r "$gpu/power/runtime_status" ]] || continue
  printf '  NVIDIA %s: runtime %s, control %s\n' "${gpu##*/}" "$(cat "$gpu/power/runtime_status")" "$(cat "$gpu/power/control")"
done
holders=$(find /proc/[0-9]*/fd -lname '/dev/nvidia*' 2>/dev/null | cut -d/ -f3 | sort -u || true)
if [[ -n "$holders" ]]; then
  printf '  Processes keeping the NVIDIA GPU awake:\n'
  for pid in $holders; do printf '    %s %s\n' "$pid" "$(cat "/proc/$pid/comm" 2>/dev/null)"; done
fi
if command -v umbriel >/dev/null 2>&1 && umbriel outputs --json >/dev/null 2>&1; then
  umbriel outputs --json | jq -r '.[] | select(.enabled) | "  Refresh \(.name): \((.modes[] | select(.current)).refresh_mhz / 1000) Hz"' || true
fi
printf '  Expect "suspended" for NVIDIA on battery when no game or offloaded app runs.\n'

if command -v systemd-analyze >/dev/null 2>&1; then
  printf '\nBoot timing:\n'
  systemd-analyze time || true
fi
if command -v systemctl >/dev/null 2>&1; then
  printf '\nFailed system units:\n'
  systemctl --failed --no-legend --plain || true
fi
if command -v free >/dev/null 2>&1; then
  printf '\nMemory:\n'
  free -h
fi
printf '\nUse journalctl -b -p err for errors and previous boot entries for comparisons.\n'
