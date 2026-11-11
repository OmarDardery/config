#!/usr/bin/env bash
# Read-only post-boot checks for the NixOS desktop.
set -euo pipefail

hardware_check() {
  printf '\n=== ASUS hardware validation ===\n'
  printf 'Suspend support: '
  if [[ -r /sys/power/state ]]; then
    cat /sys/power/state
  else
    printf 'not exposed\n'
  fi
  if [[ -r /sys/power/mem_sleep ]]; then
    printf 'Suspend-to-RAM mode: '
    cat /sys/power/mem_sleep
  fi

  printf '\nDisplay connectors (kernel DRM):\n'
  local found=0 connector status
  for status in /sys/class/drm/card*-*/status; do
    [[ -r "$status" ]] || continue
    connector=${status%/status}
    printf '  %s: %s\n' "${connector##*/}" "$(cat "$status")"
    found=1
  done
  (( found )) || printf '  No DRM connector status files accessible\n'
  printf 'Note: connected means cable detected, not that the display renders correctly.\n'

  printf '\nBluetooth controller:\n'
  if command -v bluetoothctl >/dev/null 2>&1; then
    bluetoothctl show 2>&1 | head -n 15 || true
  else
    printf '  bluetoothctl not installed\n'
  fi
  if command -v rfkill >/dev/null 2>&1; then
    rfkill list bluetooth || true
  fi
  if command -v systemctl >/dev/null 2>&1; then
    printf 'Bluetooth service: '
    systemctl is-active bluetooth.service || true
  fi

  printf '\nBattery charge thresholds:\n'
  local battery threshold any=0
  for battery in /sys/class/power_supply/BAT*; do
    [[ -d "$battery" ]] || continue
    any=1
    threshold="$battery/charge_control_end_threshold"
    if [[ -r "$threshold" ]]; then
      local value
      value=$(cat "$threshold")
      printf '  %s: %s%% (target: 80%%)\n' "${battery##*/}" "$value"
      if [[ "$value" != 80 ]]; then
        printf '  WARNING: expected 80%%. Check the udev battery rule and firmware support.\n'
      fi
    else
      printf '  %s: kernel exposes no charge_control_end_threshold\n' "${battery##*/}"
    fi
  done
  (( any )) || printf '  No battery detected\n'

  printf '\nRecent sleep and resume logs (current boot):\n'
  if command -v journalctl >/dev/null 2>&1; then
    journalctl -b --no-pager -o short-iso \
      -u systemd-suspend.service -u systemd-logind.service -n 30 2>&1 || true
  fi
  printf '\nSuspend/resume requires a physical test; connected displays and Bluetooth devices must be checked manually.\n'
}

case "${1:-}" in
  --hardware)
    hardware_check
    exit 0
    ;;
  --suspend-test)
    [[ $# == 1 ]] || { printf 'Usage: config-doctor --suspend-test\n' >&2; exit 2; }
    if [[ ! -w /sys/power/state ]]; then
      printf 'Suspend may require authentication through logind/polkit.\n'
    fi
    printf 'Save work first. This will suspend the laptop NOW; ensure you can wake it with the power button.\n'
    printf 'Proceed? Type YES: '
    read -r confirmation
    [[ "$confirmation" == YES ]] || { printf 'Cancelled.\n'; exit 0; }
    before_boot=$(cat /proc/sys/kernel/random/boot_id)
    before_time=$(date --iso-8601=seconds)
    systemctl suspend
    after_boot=$(cat /proc/sys/kernel/random/boot_id)
    printf '\nSleep requested at: %s\n' "$before_time"
    if [[ "$before_boot" != "$after_boot" ]]; then
      printf 'Boot ID changed: system restarted rather than resuming in the same boot.\n'
    else
      printf 'Returned to the same boot (does not prove all devices resumed correctly).\n'
    fi
    hardware_check
    exit 0
    ;;
  "") ;;
  *)
    printf 'Usage: config-doctor [--hardware|--suspend-test]\n' >&2
    exit 2
    ;;
esac

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
