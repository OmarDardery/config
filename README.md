# Desktop configuration

One setup command, two scopes:

| System | Managed here |
| --- | --- |
| NixOS, x86_64 | Full desktop, apps, services, hardware integration and Home Manager |
| Other Linux distros | LazyVim, VSCodium, Umbriel, Noctalia, Kitty, Starship and Zsh dotfiles only |

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
installation, native Git or native Python installation is required beforehand.
Once flakes are enabled, the command shortens to `nix run github:OmarDardery/config`.

**Other distros:** Nix supplies the small Git/Python activation environment.
Only dotfiles are applied; desktop applications remain installed through your
distro's package manager. Your Nix profiles and project development environments
remain available for development tools. The installer does not enable services,
change your login shell or select a desktop session. Select your distro's Umbriel
session to use the desktop. See [native requirements and files](non-nixos/README.md).

Existing file conflicts are backed up. On non-NixOS, subsequent applies preserve
local edits and deletions. NixOS preferences are managed directly by Home Manager;
edit their source and rebuild. LazyVim downloads its plugins on first launch;
project tools belong in each project's `shell.nix` or native environment.

## Apply and update

After restarting Zsh:

| Command | NixOS | Other Linux |
| --- | --- | --- |
| `up` | Refresh flake inputs, then rebuild | Fast-forward the checkout, then apply dotfiles |
| `config-apply` / `rebuild` | Apply local config | Apply local dotfiles |
| `nupdate` | Refresh only the flake lock | — |
| `nbuild` | Build without activating | — |
| `cnf` / `cconf` | Edit / enter the checkout | — |

The commands also work outside Zsh. Native launchers live in `~/.local/bin`; use
the full path if your current shell has not added it to `PATH` yet.

NixOS `up` runs `nix flake update` against the local checkout and keeps your
source edits. It does not pull Git commits. To receive repository changes, run
`git -C ~/config pull --ff-only`, then `up`. Review and commit changed lockfiles.
An input with an explicit commit/tag stays pinned until its URL is changed.
Native `up` refuses tracked source edits or a diverged checkout; it does not
update native packages. The launchers use Nix for their Git/Python runtime. Use your distro's normal package updater.

## Hardware and optional features

Generic machines use the stable kernel and their generated hardware settings.
The ASUS TUF A14 (FA401) is detected automatically and uses the existing tested
NVIDIA/PRIME, kernel and display policy. Override detection with `--hardware
generic` or `--hardware asus-tuf-a14`. Other NVIDIA machines need their own driver
module. The personal XFS storage mount is added only if its UUID exists locally.

Steam and everyday desktop apps remain enabled. Docker, engineering tools,
printers/scanners, diagnostics, Tailscale and daily Restic backups default off.
Enable the needed `workstation.<feature>.enable` options in
[nixos/configuration.nix](nixos/configuration.nix). Backup details and recovery
are in [nixos/BACKUPS.md](nixos/BACKUPS.md).

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
# Native Linux: apply without pulling
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

Home Manager backs up initial conflicts with `.bak`; move an existing `.bak`
aside before retrying a conflict. NixOS's normal activation uses systemd.

[NixOS notes](nixos/README.md) · [Manual Nix apps](nixos/APPS.md) ·
[Shortcuts](nixos/SHORTCUTS.md) · [Theming](nixos/THEMING.md)
