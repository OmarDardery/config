# Desktop configuration

One setup command, two scopes:

| System | Managed here |
| --- | --- |
| NixOS, x86_64 | Full desktop, apps, services, hardware integration and Home Manager |
| Other Linux distros | Standalone Home Manager: desktop essentials, editors, fonts, user Flatpaks and dotfiles |

## Install

With Nix installed, run as your normal user on either NixOS or another Linux distro:

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

**NixOS:** no Git/flake setup is required beforehand. The launcher uses Nix to
clone into `~/config`, copies the installed hardware config, captures the current
system/Home Manager state versions and standard GRUB/systemd-boot settings, then
runs one `sudo nixos-rebuild switch`. Your current user and home are used. It does
not modify `/etc/nixos`. It supports the normal installed GRUB and systemd-boot
layouts; custom bootloader modules may need manual configuration.

The same command detects the operating system. No clone, separate Home Manager
installation or native Git installation is required beforehand.
Once flakes are enabled, the command shortens to `nix run github:OmarDardery/config`.

**Other distros:** standalone Home Manager installs the editors,
LibreOffice, Xournal++, file/media/password tools, Kitty/Zsh/Starship and fonts.
On x86_64 it also installs Steam, ProtonPlus, OrcaSlicer and Discord as user
Flatpaks. Missing native Flatpak/portal support is installed through the distro
package manager with sudo; build-only mode skips host changes. The distro keeps
its desktop session, drivers and login shell selection. See
[standalone setup and migration](non-nixos/README.md).

Home Manager owns configured preferences on both paths. Existing file conflicts
are backed up; edit sources in the repository and apply again. LazyVim downloads
plugins on first launch. Project tools belong in each project's environment.

## Apply and update

After restarting Zsh:

| Command | NixOS | Other Linux |
| --- | --- | --- |
| `up` | Refresh flake inputs, then rebuild | Refresh flake inputs, then apply Home Manager |
| `config-apply` / `rebuild` | Apply local config | Apply local Home Manager config |
| `nupdate` | Refresh only the flake lock | — |
| `nbuild` | Build without activating | — |
| `cnf` / `cconf` | Edit / enter the checkout | — |

The `config-apply` command also works outside Zsh. Home Manager installs it in
your Nix profile; reload the Nix environment if it is not yet on `PATH`.

NixOS `up` runs `nix flake update` against the local checkout and keeps your
source edits. It does not pull Git commits. To receive repository changes, run
`git -C ~/config pull --ff-only`, then `up`. Review and commit changed lockfiles.
An input with an explicit commit/tag stays pinned until its URL is changed.
Non-NixOS `up` also updates its local lockfile without pulling Git commits.
Use your distro's updater for native packages.

## Hardware and optional features

NixOS uses Ly with its built-in Matrix animation for login, then starts Umbriel.
The non-NixOS path uses standalone Home Manager; use your distro to manage Ly.

All NixOS machines use the latest kernel available in the pinned Nixpkgs input.
Generic machines use their generated hardware settings.
The ASUS TUF A14 (FA401) is detected automatically and uses the existing tested
NVIDIA/PRIME and display policy. Override detection with `--hardware
generic` or `--hardware asus-tuf-a14`. Other NVIDIA machines need their own driver
module. The personal XFS storage mount is added only if its UUID exists locally.

Steam/GameMode, the everyday apps, FreeCAD/PlatformIO, Docker, printing/scanning,
diagnostics and Tailscale are included by default. Flathub is configured and
OrcaSlicer/ProtonPlus are installed as system Flatpaks. Existing unmanaged Flatpaks
are preserved; configured apps update at activation. Downloads require Internet
access and may take time on a fresh install.

Set individual `workstation.<feature>.enable = false;` options in
[nixos/configuration.nix](nixos/configuration.nix) to opt out. Restic backups
activate by default when the personal storage disk is configured; see
[nixos/BACKUPS.md](nixos/BACKUPS.md).

Nix uses two concurrent build jobs, four cores per job and lower scheduling
priority. The desktop uses the native scheduler, power-profiles-daemon and zram.
No desktop reconciliation service, extra scheduler daemon, global language
runtimes, shared dev shells or project templates are configured.

## Local use and recovery

From a checkout, `bash setup.sh` selects the appropriate installer. Examples:

```sh
# Fork or different checkout location
bash setup.sh YOURNAME/config --repo-dir ~/dotfiles
# NixOS: inspect a full build without switching
bash setup.sh --build-only
# Other Linux: apply standalone Home Manager
nix run "path:$HOME/config/non-nixos" -- --repo-dir "$HOME/config"
```

`--ref BRANCH` selects a revision for a **new** checkout. When testing an unmerged
branch, select that branch in the launcher URL too and use a fresh checkout.
Existing repositories are never reset or switched automatically.

Generated `nixos/local-profile.nix`, `local-system.json` and
`hardware-configuration.nix` stay local. Use `path:` with direct rebuilds so Nix
includes those ignored files:

```sh
sudo nixos-rebuild switch --flake "path:$HOME/config#nixos"
sudo nixos-rebuild switch --rollback
```

On NixOS, Home Manager backs up initial conflicts with `.bak`; move an existing
`.bak` aside before retrying a conflict. Standalone activation uses unique backup suffixes. NixOS's normal activation uses systemd.

[NixOS notes](nixos/README.md) · [Manual Nix apps](nixos/APPS.md) ·
[Shortcuts](nixos/SHORTCUTS.md) · [Theming](nixos/THEMING.md)
