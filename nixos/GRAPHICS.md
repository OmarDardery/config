# Laptop Graphics Notes

These are preserved observations from the earlier investigation, not new tests
or claims about current upstream issue status. The cleanup does not change the
kernel, NVIDIA pin, power-management flags or rendering workarounds.

## Two Different Symptoms

- Pink/blue stripes affected tiled windows but not fullscreen games or captures.
  `AMD_DEBUG=nodcc` disables radeonsi Delta Color Compression and was confirmed to
  fix those stripes. It costs memory bandwidth, not visual effects, and needs a
  fresh login to apply.
- Independent flicker began around 2026-08-06: window content briefly exposed
  sharp wallpaper while borders/tab indicators remained. It was worse on battery.
   The former Niri configuration used `wait-for-frame-completion-before-queueing`.
   That compositor-specific configuration was removed when Umbriel became primary.

## Earlier Tests

The recorded investigation did not resolve the flicker by disabling blur,
shadows, corners or opacity; reverting to Linux 6.18 and the 2026-08-04 config;
reverting the lockfile; adding nodcc; or testing PSR/PSR-SU/Replay/IPS via
`amdgpu.dcdebugmask=0xE10`. VRR was off, panel rendering/scanout used the same GPU,
adaptive backlight was disabled, and no display underflows were observed.

The symptom matched the single-frame flicker described in niri-wm/niri#2030,
including reports on NVIDIA hardware at high refresh rates. The frame-completion
workaround was referenced in niri-wm/niri#2477. `disable-direct-scanout` was noted
as a possible further test but had not been tested; it is not a ruled-out cause.

Lower refresh rates reduced symptoms by widening the frame budget, but did not
establish a hardware-clock cause. Do not restore the old profile-based
60/100/165 Hz switching service or remove visual effects as a purported fix.

Recorded battery measurements were 800 MHz core / 400 MHz memory, versus maxima
2700/937, and 16-22% GPU utilization in the quiet/power-saver profile. Those
measurements do not by themselves explain the cross-hardware flicker.

Keep the `amdgpu_dpm` power-profile action disabled: its recorded policy selected
`low` for power saver and `auto` otherwise, never `high`. NVIDIA runtime suspend
was already working with `finegrained = false`; changing that flag needs separate
suspend testing, not an assumed battery benefit.
