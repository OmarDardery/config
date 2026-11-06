# Desktop configuration

One entry point for NixOS and other Linux distributions:

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

Run as your normal user. The installer clones into `~/config` and records local
identity without committing machine-specific files.

| System | Scope |
| --- | --- |
| NixOS, x86_64 | Desktop, apps, hardware/services and integrated Home Manager |
| Other Linux, x86_64/aarch64 | Standalone Home Manager apps, fonts, dotfiles and supported user Flatpaks |

NixOS captures the installed hardware, bootloader and state versions before its
first rebuild. Other distros keep their existing desktop session and drivers;
missing native Flatpak prerequisites use the distro's package manager with sudo.
Configured files are backed up before Home Manager takes ownership.

## Daily use

| Command | Action |
| --- | --- |
| `config-apply` / `rebuild` | Apply the local checkout |
| `up` | Update the active flake's lockfile, then apply |
| `config-apply --build-only` | Build without activating or installing host prerequisites |

`up` preserves source edits and does not pull Git commits. To receive repository
changes, run `git -C ~/config pull --ff-only`, then `up`. Review and commit changed
lockfiles. Restart Zsh after the first activation to pick up aliases.

From a checkout, `bash setup.sh` uses the same installer. Use `--repo-dir DIR` for
another location, or `OWNER/REPO` for a fork. `--ref BRANCH` applies only to a new
clone; select that branch in the initial `nix run` URL too. Existing checkouts are
never reset or switched automatically.

## Where settings belong

| Location | Responsibility |
| --- | --- |
| `flake.nix` | NixOS output and operating-system routing |
| `nixos/configuration.nix` | Machine composition and feature defaults |
| `nixos/system/` | System features and services |
| `nixos/home/` | NixOS user configuration and desktop integration |
| `non-nixos/home/` | Standalone desktop and shared editor modules |
| `non-nixos/packages.nix` | Shared desktop app and font selections |
| `non-nixos/dotfiles/` | Shared static app settings |
| `scripts/`, `non-nixos/*.sh` | Installers and native host integration |
| `tests/` | Isolated regression and CI checks |

Edit sources here and reapply. Extra Neovim Lua files, VSCodium keybindings and
`.zshrc.local` remain available. Project toolchains belong in each project's own
environment; there are no shared development shells or global language runtimes.

## NixOS defaults and recovery

Every NixOS host uses the latest kernel in the pinned Nixpkgs input. The ASUS TUF
A14 profile adds NVIDIA/PRIME, peripherals and an 80% battery cap. Ly supplies the
Matrix login screen; Umbriel starts Noctalia. Generic hosts use their generated
hardware configuration.

Gaming, engineering, Docker, printing, diagnostics and Tailscale default to on.
Set `workstation.<feature>.enable = false;` in `nixos/configuration.nix` to opt out.
The personal data mount and backups are enabled only when the disk is detected.

Ignored hardware, identity and state-version files must be included with `path:`:

```sh
sudo nixos-rebuild switch --flake "path:$HOME/config#nixos"
sudo nixos-rebuild switch --rollback
```

State versions stay fixed across updates. NixOS uses `.bak` conflict backups;
standalone Home Manager uses unique backup suffixes. Flatpak data and versions
are outside Nix generation rollback.

## Checks

With Nix and flake support available, run the same checks as CI:

```sh
bash tests/check-native.sh x86_64-linux
bash tests/check-native.sh aarch64-linux
bash tests/check-nixos.sh
```

These use temporary profiles/hardware and never activate a home or system. Native
`nix flake check --no-build` also evaluates home generations for both architectures.

[NixOS guide](nixos/README.md) · [Standalone guide](non-nixos/README.md) ·
[Manual Nix apps](nixos/APPS.md) · [Shortcuts](nixos/SHORTCUTS.md) ·
[Theming](nixos/THEMING.md) · [Backups](nixos/BACKUPS.md)
