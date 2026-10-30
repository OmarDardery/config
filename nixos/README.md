# Configuration notes

`flake.nix` imports this host and `home/default.nix` directly. This is a personal
system configuration: there are no development shells, custom test framework or
language-toolchain catalogue.

| Location | Purpose |
| --- | --- |
| `profile.nix` | Account, host and checkout location |
| `configuration.nix` | Host entry point and optional application choices |
| `hardware-configuration.nix` | Generated locally, ignored by Git |
| `hardware.nix` | Laptop GPU, peripherals and storage |
| `system/` | Boot, desktop, networking, backups and optional bundles |
| `system/applications/` | Everyday applications and desktop services |
| `home/` | Shared dotfiles and small editor preferences |
| `pkgs/` | Desktop helpers and necessary package overrides |
| `native/` | Debian/Fedora application installation |

The direct structure takes inspiration from
[Misterio77's minimal starter](https://github.com/Misterio77/nix-starter-configs/tree/main/minimal).
Neovim follows the [LazyVim starter](https://github.com/LazyVim/starter), with Nix
support and the existing desktop palette instead of a preinstalled language suite.

## Applying changes

Use `path:` flake references so the ignored local hardware file participates.
The setup script copies it from `/etc/nixos`, backing up a changed predecessor:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos-setup.sh
```

Do not change `system.stateVersion` or `home.stateVersion` as part of an upgrade.
On another machine, adapt `profile.nix`, review `hardware.nix` and provide that
machine's generated hardware configuration.

For an existing Debian/Fedora installation with Nix and native applications:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate --backup-extension bak
```

Standalone `oad` and `oad-desktop` outputs retain the same full dotfile scope.
They install no applications. Their names follow `profile.nix`.

## Editors and project tools

NixOS installs regular VSCodium and Neovim with only Nix tooling. LazyVim downloads
its plugins on first use; those plugins are managed by Lazy rather than a second
Nix package catalogue. Mason and Neovim's language providers are disabled.
VSCodium permits manually installed extensions. Neither editor gets a Python
virtual environment, Jupyter kernel, language extras, compiler suite or debugger
from this configuration.

Use each project's own environment for language packages. `editor-setup` on other
distributions only syncs editor plugins and the small extension list. Old manually
created `editor-python` environments and user-installed extensions are not erased;
remove them yourself if you no longer use them. Managed notebook configuration
and kernels disappear when Home Manager applies the new generation.

## Desktop and maintenance

Home Manager writes preferences. NixOS or the native distribution owns desktop
services, portals and applications. `desktop-apply` runs at graphical login;
activation does not need a running compositor or network downloads.

Optional bundles own their packages, services and Flatpaks. Disabling one does
not erase application data. Existing Flatpaks are retained, and fonts remain
available through the read-only `/usr/share/fonts` mount.

Backups use `/mnt/storage/backup`; see [BACKUPS.md](BACKUPS.md) for recovery and
password storage. Docker is socket-activated when the containers bundle is enabled.
The NVIDIA/kernel pair, state versions and storage policy are unchanged.

GitHub Actions performs ordinary Nix evaluation against disposable hardware and
both standalone home outputs. It never activates or deploys that hardware.
For a real machine, build the system before switching and test login/suspend
when changing graphics or display-manager settings.
