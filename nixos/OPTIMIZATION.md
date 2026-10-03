# Configuration Audit

## Current Design

- `profile.nix` owns deployment identity, paths and selected output names.
  Both Home Manager profiles share user package policy; the host's proprietary
  driver policy is separate from WinBoat's user-only insecure runtime exception.
- Home Manager owns applications, shell/editors, dotfiles, fonts/cursor,
  Noctalia/plugins, compositor settings, user services and user Flatpaks.
- Native host responsibilities are boot/storage, kernel drivers, accounts,
  permissions, login/PAM integration, firewall and system daemons. See the
  feature checklist in ../README.md for non-NixOS requirements.
- GNOME apps, GVfs, KDE Connect, Flatpak CLI/installations, GameMode, capture GUIs
  and laptop user utilities are home-owned. Privileged helper wrappers, udev/PAM,
  native GNOME session services and pre-login greeter resources remain outside.
- Standalone Linux registers the complete Nix user portal stack through Home
  Manager's systemd/D-Bus package APIs. This is an explicit user-stack choice,
  not a promise to leave every native desktop portal untouched.
- Repeated cursor/fonts for the greeter, shared tools on editor wrapper PATHs,
  and Nautilus/Papers for standalone use are intentional. The same derivation
  is not downloaded twice just because it has multiple consumers.

## Simplifications

- Removed unused Antigravity system-overlay plumbing, unused flake arguments,
  duplicate commented driver pins and duplicated package-policy declarations.
- Shared nixd settings and runtime lists across active editors/dev shells.
  Disabled inherited nil_ls and removed inactive/default-only LazyVim entries.
- PlatformIO's IDE now uses the Nix Core instead of its own Core/Python download.
  Project frameworks/cross-compilers and optional notebook/debugging workflows
  remain available.
- Kept one KDE Connect installation per backend and removed Umbriel's redundant
  Xwayland package; its upstream wrapper already supplies Xwayland.
- Simplified Noctalia settings merging while retaining deliberate standalone
  removal of NixOS-only widgets/settings and opt-in state reconciliation.
- Generated palettes respect custom XDG locations. Umbriel is the default
  compositor, with the shared cursor and English/Arabic keyboard settings.
- Noctalia owns supported application colors. VSCodium's static palette is gone;
  GTK/Qt, Zen, Steam/Millennium, editors and terminal tools consume generated colors.
  Community templates and Steam integration are pinned; see ../README.md.
- Bootstrap derives deployment defaults, preserves checkouts/locks/hardware,
  builds before activation and offers explicit standalone conflict backups.
- Fedora/Debian prerequisite setup is explicit preview/apply, independent of
  builds. It preserves existing networking/audio/firewall/SELinux policy and
  refuses unsupported variants or systemd <254 instead of upgrading core services.

The kernel, NVIDIA driver pin, visual effects, resource controls, recorded
graphics workarounds and both state-version values were not changed by cleanup.
Details of the preserved graphics investigation are in GRAPHICS.md.

## Resource And Security Policy

- Keep two Nix builds/four cores, zram, weekly garbage collection, store
  optimization and ten boot entries for this laptop's resource limits.
- LocalSend is removed. KDE Connect's TCP/UDP 1714-1764 range is open on all
  networks by request; the remaining firewall stays enabled. Existing mDNS
  UDP 5353 is separate and unchanged.
- WinBoat's EOL Electron exception and docker-group access are explicitly
  accepted risks. Rootless Docker was not assumed compatible with WinBoat.
- KMS recording's CAP_SYS_ADMIN helper is restricted to the recording group.
  clangd's driver execution allowance is narrowed to cross-GCC compiler names.
- Noctalia plugins are trusted code. Targeted scratch-file/process fixes are
  documented in pkgs/noctalia-plugins.md; upload actions remain external services.
- No disk-encryption work or planning is included.

## Verification

Both deployment profiles build and evaluate without failed assertions/warnings.
Tests cover real alternate-user/custom-path Home Manager instantiation,
bootstrap compatibility/safety guards and opt-in state reconciliation. Generated
Umbriel configs, editor Lua/Nix expressions and portal registration are
checked without activating foreign-distro sessions. `tests/theme-rendering.py`
renders all 13 application templates in both modes without executing their hooks.

These checks do not replace graphical foreign-distro testing, native PAM/device
integration, printer operations, real Proton downloads or hardware suspend/offload
tests. Umbriel remains pre-release software. Molten remote-plugin registration
remains an explicitly documented manual operation.

## Last Activation Record

The earlier follow-up was activated without another reboot. It removed
LocalSend, reconciled Noctalia state, regenerated its live Niri theme, verified
the Bluetooth proxy and migrated OrcaSlicer 2.4.2/ProtonPlus 0.6.8 to user installs.
Both apps produced startup windows; system app duplicates were removed without
`--delete-data`. Both old/new NVIDIA Flatpak extensions were retained.

Noctalia backup:
`~/.local/state/noctalia/settings.toml.backup-1790974580636812518-qfo8swpm`

Application config/data backup, excluding caches:
`~/.local/state/configs-backups/flatpak-migration-20261002T203459Z-ebFewD/flatpak-orcaslicer-protonplus-settings.tar.gz`

At that activation, the loaded NVIDIA module was 595.91.07 and configured
userspace was 610.57.04, so host NVML reported a mismatch until another boot.
The cleanup does not unload drivers, reboot, switch desktops or change live
Noctalia state. Build the candidate before explicitly activating it.
