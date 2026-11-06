# Standalone Linux desktop essentials

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

Run as your normal Linux user with Nix installed. Supports x86_64 and aarch64.
The launcher clones into `~/config`, records the local identity, and applies
standalone Home Manager. From an existing checkout use `bash setup.sh`.

| Use | Provided apps |
| --- | --- |
| Editors/development | VSCodium, Neovim/LazyVim, Git, ripgrep, fd, nixd, nixfmt |
| Browser | Firefox |
| Office, notes and PDFs | LibreOffice, Xournal++, Papers, English spellchecking |
| Files and archives | Thunar, File Roller, unzip, 7-Zip |
| Images, audio and video | GIMP, imv, mpv |
| Passwords | KeePassXC |
| Terminal and shell | Kitty, Zsh, Starship, zoxide, direnv, btop |
| Desktop helpers | Calculator, volume mixer, clipboard/screenshot tools, brightness/media controls |
| Fonts | Inter, JetBrainsMono Nerd Font, Noto, emoji |
| x86_64 user Flatpaks | Steam, ProtonPlus, OrcaSlicer, Discord |

Home Manager installs the Nix apps, fonts, associations and dotfiles. The distro
continues to own its desktop session, drivers, audio services, portals and login
manager. Umbriel/Noctalia settings remain available if you use that session;
existing GNOME/KDE/Xfce sessions are not replaced. Zsh is installed without
changing your login shell; run `zsh` to use the configured shell.

## Flatpak installation

Steam and ProtonPlus use the native Flatpak sandbox and GPU integration. Their
Flathub IDs, along with OrcaSlicer and Discord, are declared in `home/flatpak.nix`.
They are enabled on x86_64; ARM gets the remaining desktop essentials without
trying to install unsupported gaming apps.

If Flatpak is missing, the normal installer uses sudo to install native Flatpak
and portal support on apt, dnf, pacman or zypper systems. On other systems it
stops with instructions to install the host prerequisite. If Flatpak is already
installed, no host package operation is performed. Keep your distro desktop's
portal backend available for screen sharing and file dialogs.

Flatpaks install synchronously during Home Manager activation, under the current
user. Download failures fail activation visibly. No systemd user service is
required. Existing unmanaged apps, remotes and data are preserved. Reapplying
updates declared apps with `--or-update`; network access is required. Initial
Steam/game/runtime downloads can be large. The Flatpak sandbox uses distro GPU
support; it does not install the NixOS NVIDIA driver.

Disable Flatpaks in `home/default.nix` with `desktop.flatpak.enable = false;`, or
set `desktop.flatpak.packages = [ ... ];` to change the list. A disabled or empty
list requires no native Flatpak setup. Direct `home-manager switch` expects host
prerequisites to be installed already; `config-apply` handles that preflight.
Build-only mode never installs host packages or runs Flatpak operations.

## Apply and update

| Command | Action |
| --- | --- |
| `config-apply` / `rebuild` | Apply the current checkout, including declared Flatpaks |
| `up` | Update this flake's lockfile, then apply |
| `config-apply --build-only` | Build a home generation without activating |
| `home-manager generations` | List generations and activation paths |

`up` preserves source edits and does not pull Git commits. Receive source changes
with `git -C ~/config pull --ff-only`, then run `up`. Restart Zsh or log out/in
after the first activation so desktop launchers and session variables refresh.
In another shell, source `~/.nix-profile/etc/profile.d/hm-session-vars.sh`.

Use `--repo-dir DIR` for a different checkout, `-- OWNER/REPO` for a fork, and
`--ref BRANCH` only for a new clone. Select that branch in the initial `nix run`
URL too when testing an unmerged branch. Existing branches are never reset.
The independent entry point is:

```sh
nix run 'github:OmarDardery/config?dir=non-nixos'
```

Direct use after bootstrapping:

```sh
home-manager switch --flake "path:$HOME/config/non-nixos#$(id -un)"
```

`local-profile.json` records identity, architecture, checkout, XDG config/data/state
paths, Zsh directory and initial state version. It stays out of Git. Keep
`stateVersion` when updating; moving a checkout refreshes `configRepo` on apply.
Flake evaluation stays pure. No shared development shells or global project
language runtimes are added.

## Migration, edits and recovery

Home Manager owns configured files as store symlinks. Edit their sources in this
repository and reapply. Conflicting files receive unique `.before-home-manager-*`
backups. Earlier copier backups remain in `~/.local/state/non-nixos-config/backups`.
Extra Neovim Lua files, VSCodium keybindings and `.zshrc.local` remain yours.
LazyVim fetches plugins on first use; project language tools belong in project
environments. Mason and Tree-sitter compilation start disabled.

No GUI apps are started or restarted during activation. For Nix GUI driver
integration, follow `targets.genericLinux.gpu` guidance printed by Home Manager.
Proprietary NVIDIA library versions must match the distro driver.

To roll back managed files/Nix packages, run an older generation's `activate`
script shown by `home-manager generations`. Flatpaks update outside the Nix store;
rolling back a Nix generation does not roll back Flatpak application versions.

The layout follows [Misterio77's starter](https://github.com/Misterio77/nix-starter-configs/tree/main/minimal),
[standalone configurations](https://github.com/GooseRooster/home-manager), and the
[Home Manager manual](https://nix-community.github.io/home-manager/installation/standalone.html).
