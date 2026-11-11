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
