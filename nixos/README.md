# NixOS configuration

The root flake imports `configuration.nix` and integrates Home Manager as a
NixOS module. `hardware.nix` is selected automatically only for the ASUS TUF A14 (FA401).
Generated hardware, account settings, state versions and boot target stay local
and ignored by Git. Other hosts use generic hardware. x86_64 NixOS hosts use the CachyOS release
kernel via the upstream pinned overlay.

## Structure

| Location | Responsibility |
| --- | --- |
| `configuration.nix` | Compose the desktop, Home Manager and feature defaults |
| `profile.nix` | Account and deployment values, with local overrides |
| `hardware.nix` | ASUS GPU, peripherals and battery policy |
| `system/default.nix` | Explicit list of system modules |
| `system/<feature>.nix` | A feature's option, packages, services and permissions |
| `system/applications/` | Everyday apps, CLI utilities, fonts and display tools |
| `home/` | User programs and preferences |
| `../non-nixos/` | Independent native Linux dotfile installer |

Change `workstation.<feature>.enable` in `configuration.nix` to choose bundles.
Each feature declares its own option beside its implementation and defaults to
off when imported alone. The desktop entry point enables your usual bundles.
Diagnostics owns both its tools and MTR; Tailscale owns its VPN and firewall rules.
Add a system module to `system/default.nix` explicitly; there is no auto-discovery
or module-generation framework. Keep closely related settings in one file and
split only when a feature has a separate purpose or switch.

## Apply and update

From any directory, after initial setup:

```sh
sudo nixos-rebuild switch --flake "path:$HOME/config#nixos"
```

Use the root flake, not `~/config/nixos`. The explicit `path:` includes ignored
`nixos/hardware-configuration.nix` and `nixos/local-profile.nix`. A Git-style
`--flake .` excludes them. Do not stage generated hardware to work around this.

The initial `nix run github:OmarDardery/config` clones once, prepares those
local files and calls ordinary `nixos-rebuild`. An existing checkout is kept;
source updates use `git -C ~/config pull --ff-only`. `nixos-rebuild` builds before
switching, so there is no second pre-build or custom activation service.

After a successful rebuild, reload the open shell with `exec zsh`. Existing
shells retain aliases from the previous generation. The aliases use checkout-bound commands:

| Command | Action |
| --- | --- |
| `up` | Update local flake inputs, then rebuild |
| `rebuild`, `config-apply` | Apply local settings without updating inputs |
| `nbuild` | Build without activating |
| `config-apply --boot-only` | Install a boot generation safely without switching the current session |
| `config-doctor` | Report read-only post-boot hardware and service status |
| `cnf`, `cconf` | Edit or enter the checkout |

`systemd-run` in rebuild output is part of upstream NixOS activation. It is
expected: NixOS uses systemd to manage services and switch configurations. A
reported failed unit is the thing to diagnose; removing systemd would break the OS.

## Desktop and apps

Ly provides the login screen using its built-in Matrix animation. This uses the
native `services.displayManager.ly` NixOS module and the pinned Nixpkgs Ly package;
no separate greeter flake or theme package is needed. Ly lists Wayland sessions
and launches Umbriel; XWayland apps continue to work inside the desktop. The
NixOS module also supplies PAM and GNOME Keyring integration.

On the first login, select Umbriel if needed. Ly remembers the selected user and
session. After applying this display-manager change, reboot to enter Ly; restarting
`display-manager.service` from the desktop would terminate the current session.

Umbriel starts Noctalia directly. Noctalia handles its own runtime state,
wallpaper colors and Kitty/Umbriel palettes. There is no `desktop-config`
service, palette seeder, state reconciler or font-cache refresh service.
Screenshots use Noctalia's native commands. Community plugins are not enabled
by this configuration; add them through Noctalia if wanted.

Home Manager directly owns editor settings, shell files and desktop dotfiles.
Edit Nix-managed preferences in `home/` and rebuild. Existing conflicting files
are backed up using Home Manager's `.bak` policy; if a `.bak` already exists,
move it aside before retrying. Extra local LazyVim files and user-installed
Codium extensions remain yours. Plugins are downloaded by LazyVim on first use;
language toolchains belong in each project’s own `shell.nix`.

Steam and GameMode use the normal NixOS modules. There is no Millennium/client
fork or theme installer. Engineering tools are included by default. FreeCAD and
PlatformIO use Nix;
OrcaSlicer and ProtonPlus use the declared Flathub installation. Existing Flatpak
apps/data are preserved and configured apps update during activation. The font
mount remains for sandbox compatibility.

The kernel scheduler and power-profiles-daemon handle normal power management.
Choose power profiles through Noctalia or `powerprofilesctl`; there is no extra
scheduler daemon or script that changes profiles when the power source changes.
CachyOS latest is selected in `system/performance.nix`; the ASUS NVIDIA
driver pin stays in its hardware profile. The installed boot
target and state versions are captured once in `local-system.json`; updates do
not advance state versions. The personal data disk is mounted only when detected.
Tailscale, Docker and diagnostics are enabled by default. Printing/scanning,
including their discovery services, are disabled until
`workstation.printing.enable = true;` is selected.
Backups are enabled when the personal storage disk is configured.

OpenTabletDriver manages tablet settings through its GUI. The optional preset
is `assets/tablet-settings.json`; it is not repeatedly merged into your live
settings. Xournal++ manages its own pen-button preferences too.

## Recovery

If a switch reports a failure, read the named unit's journal. The old
`desktop-config.service` is removed by this configuration. Exit/re-enter the
graphical session after rebuilding to run the matching desktop binaries.

```sh
systemctl --user --failed
journalctl --user -b -u UNIT_NAME
sudo nixos-rebuild switch --rollback
```

For kernel/NVIDIA upgrades, use `config-apply --boot-only`, reboot, then run
`config-doctor`; choose the previous NixOS boot generation if graphics fail.
Build and validate before changing graphics or display-manager settings. Remote
evaluation cannot test the laptop's displays, tablet or suspend/resume behavior.

## Manual apps and package ownership

Home Manager installs and configures user tools, including the shell integrations,
Git, Kitty and Yazi. NixOS owns system services and hardware. Fonts are declared
once in the system font list. Logisim Evolution and Wireshark are removed.

Use [Nix profiles](APPS.md) for apps you want outside the declarative config.
There are no shared dev shells or project templates in this repository.
