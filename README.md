# Desktop configuration

Two independent configurations:

| Configuration | Scope |
| --- | --- |
| Root `flake.nix` + `nixos/` | Full NixOS system, applications, services and integrated Home Manager |
| `non-nixos/flake.nix` | Only LazyVim, VSCodium, Umbriel and Noctalia dotfiles for native Linux apps |

## NixOS

```sh
# First setup or apply local changes
nix run github:OmarDardery/config
# Update flake inputs, build and switch
nix run github:OmarDardery/config#update
```

Run as your normal user. The launcher clones to `~/config`, generates ignored
local account settings, and copies `/etc/nixos/hardware-configuration.nix` if
missing. It runs the standard `sudo nixos-rebuild switch`, which builds the complete system
before activating, including Home Manager. `#update` updates the local `flake.lock`; it preserves your source
edits and does not pull Git commits. Pull source changes with `git pull --ff-only`
when wanted, then apply. Review and commit lockfile changes in your checkout.

**This NixOS host targets an ASUS TUF A14, x86_64, UEFI.** Review
[nixos/hardware.nix](nixos/hardware.nix) for another machine: it contains
NVIDIA/PRIME bus IDs and a storage mount. Preserve system/home state versions.

NixOS manages applications and desktop services declaratively. Home Manager
configures the shell, Git, editors, Umbriel, Noctalia and desktop preferences.
Neovim/LazyVim, VSCodium, direnv and native Steam remain available;
language toolchains load through project shells. There are no standalone home
profiles or non-NixOS graphics wrappers in this configuration.

## Fedora, Debian and other Linux

Nix must already be installed. No Home Manager installation is needed.

```sh
# Apply only the four apps' dotfiles
nix run 'github:OmarDardery/config?dir=non-nixos'
# Pull the checkout forward and apply unedited dotfile updates
nix run 'github:OmarDardery/config?dir=non-nixos#update'
```

The independent flake uses Nix only to run its small Git/Python installer. It
supports x86_64 and aarch64 Linux. Install Neovim, Git, ripgrep/fd, VSCodium,
Umbriel, Noctalia and Kitty through your distro as needed. It does not install
these apps, Steam, fonts or language tools; it does not change your shell,
services, drivers, login manager, package manager or desktop session.

Files are copied into writable user config directories. Existing conflicts are
backed up; later applies update unedited files and preserve your edits and
deletions. VSCodium extensions, profiles and keybindings remain yours. LazyVim
fetches plugins on first launch. `#update` runs `git pull --ff-only`, refusing
tracked source edits or a diverged checkout before touching dotfiles.
See [non-nixos/README.md](non-nixos/README.md) for paths, backups and requirements.

## Rebuild troubleshooting

The flake is at `~/config`, not `~/config/nixos`. From any directory, use:

```sh
sudo nixos-rebuild switch --flake "path:$HOME/config#nixos"
```

Keep `path:`: it includes the ignored generated hardware/account files. After
rebuilding, `exec zsh` reloads changed aliases; an already open shell still has its
old `update` definition. `systemd-run` is NixOS's normal activation mechanism.
This config no longer installs `desktop-config.service`, font-cache refresh
services, settings reconciliation scripts or a scheduler daemon.

## Options and local use

If flakes are not enabled, prefix either command with:

```sh
nix --extra-experimental-features 'nix-command flakes' run …
```

Both commands accept a repository and checkout location:

```sh
nix run github:OmarDardery/config -- YOURNAME/config --repo-dir ~/dotfiles
nix run 'github:OmarDardery/config?dir=non-nixos' -- YOURNAME/config --repo-dir ~/dotfiles
# NixOS build without activation
nix run github:OmarDardery/config -- --build-only
# From an existing clone, select the appropriate configuration
bash setup.sh
```

Repository arguments accept `OWNER/REPO`, `github:OWNER/REPO` or an HTTPS GitHub
URL with this layout. `--ref` selects a branch/tag/commit for a new clone only.
Existing checkouts are never reset or switched. To test an unmerged branch,
select it in the flake URL and with `--ref BRANCH`, using a fresh `--repo-dir`.
`setup.sh` is the only checkout launcher; distro-specific forwarding scripts are removed.

NixOS personal defaults are in [nixos/profile.nix](nixos/profile.nix).
Generated `nixos/local-profile.nix` and hardware stay ignored; `path:` builds
include them without staging. The native dotfile installer never writes them.

## Project environments

Each project owns its `shell.nix`. This system repo provides no development shells
or project templates and installs no project language toolchains globally.

Inside a project, create a `shell.nix`, for example:

```nix
{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  packages = [ pkgs.go pkgs.gopls ];
}
```

Run `nix-shell`, then `codium .` or `nvim`. Optional automatic loading uses a
project `.envrc` containing `use nix`; review it and run `direnv allow`.
`<nixpkgs>` follows the machine's Nix search path. For reproducibility, pin the
Nixpkgs source in that project. The project owns tool versions and dependencies.

For manually installed apps outside this config, see [Nix profiles](nixos/APPS.md).

## Keep it lean

NixOS specialist bundles default off. Enable `workstation.engineering.enable`,
`containers.enable`, `printing.enable` or `diagnostics.enable` in
[nixos/configuration.nix](nixos/configuration.nix) as needed. Everyday apps and
Steam remain enabled. Docker is socket-activated when enabled. Existing user
data and unmanaged Flatpaks are retained.

NixOS editor preferences are managed directly by Home Manager. Mason, Tree-sitter compilation, notebook
kernels and language providers are disabled in the starter; add tools per project.
On NixOS, `up`/`rebuild` apply, `nbuild` builds only, `update` updates inputs and
switches, `neval` checks the flake, and `cnf`/`cconf` edit/enter the checkout.
No custom desktop initialization service is installed.

NixOS recovery: `sudo nixos-rebuild switch --rollback` or a previous boot generation.
Home Manager backs up conflicting unmanaged files with a `.bak` suffix.

[Detailed NixOS notes](nixos/README.md) · [Shortcuts](nixos/SHORTCUTS.md) ·
[Theming](nixos/THEMING.md) · [Backups](nixos/BACKUPS.md)
