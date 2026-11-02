# NixOS configuration

The root flake imports `configuration.nix` and integrates Home Manager as a
NixOS module. `hardware.nix` contains ASUS TUF A14 details; generated hardware
and account settings stay local and ignored by Git.

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
shells retain aliases from the previous generation. The aliases are direct:

| Command | Action |
| --- | --- |
| `up`, `rebuild` | `sudo nixos-rebuild switch` with the absolute path flake |
| `update` | Update local flake inputs, then rebuild |
| `nbuild` | Build without activating |
| `cnf`, `cconf` | Edit or enter the checkout |

`systemd-run` in rebuild output is part of upstream NixOS activation. It is
expected: NixOS uses systemd to manage services and switch configurations. A
reported failed unit is the thing to diagnose; removing systemd would break the OS.

## Desktop and apps

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
fork or theme installer. Optional engineering uses native Nix packages, including
OrcaSlicer. Existing Flatpak applications/data are retained; use `flatpak update`
when you want to update them. The font mount remains for sandbox compatibility.

The kernel scheduler and power-profiles-daemon handle normal power management.
Choose power profiles through Noctalia or `powerprofilesctl`; there is no extra
scheduler daemon or script that changes profiles when the power source changes.
The kernel/NVIDIA pins, boot policy, disk mounts and backup jobs are retained.

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

Build and validate before changing graphics or display-manager settings. Remote
evaluation cannot test the laptop's displays, tablet or suspend/resume behavior.

## Manual apps and package ownership

Home Manager installs and configures user tools, including the shell integrations,
Git, Kitty and Yazi. NixOS owns system services and hardware. Fonts are declared
once in the system font list. Logisim Evolution and Wireshark are removed.

Use [Nix profiles](APPS.md) for apps you want outside the declarative config.
There are no shared dev shells or project templates in this repository.
