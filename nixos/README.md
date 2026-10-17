# Laptop configuration

`profile.nix` contains deployment identity. `configuration.nix` owns host
services, with hardware, desktop sessions and gaming in separate modules.
`home/` owns applications and user settings on both NixOS and standalone Linux.
`package-policy.nix` keeps application license and insecure-package exceptions
out of the host package set.

Rnote is removed; Xournal++ remains installed. Application-specific insecure
package exceptions remain limited to Home Manager's package set.

Nix limits local builds to two jobs with four cores each. Store maintenance
runs at low CPU and I/O priority, and builds trigger garbage collection below
1 GiB of free space, aiming for 5 GiB free. Live profiles remain
protected; the weekly generation cleanup retains the existing 30-day policy.
Weekly SSD TRIM is already enabled by the pinned NixOS release's defaults.

From this directory:

```sh
nix fmt path:.
nix flake check path:.
nix build path:.#nixosConfigurations.nixos.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake path:.#nixos
```

The `path:` reference includes new files before they are tracked by Git. With a
plain `--flake .`, add new configuration files to Git first.

Update inputs deliberately, then build before switching:

```sh
nix flake update nixpkgs home-manager
nix build path:.#nixosConfigurations.nixos.config.system.build.toplevel --no-link
```

Other inputs have independent pins for compatibility or binary cache reuse;
their comments in `flake.nix` explain those constraints. Keep `stateVersion`
unchanged during routine upgrades.

The Noctalia updater builds the complete system before asking to switch. If
the build fails or you decline, the updated lockfile remains for inspection.

Toolbox has a temporary override in `pkgs/jetbrains-toolbox.nix` because the
locked Nixpkgs release downloads a retired archive. It preserves upstream FHS
packaging and uses a fixed version and verified archive hash. Remove the
override when the locked Nixpkgs package has a working download. To verify a
replacement archive's unpacked hash:

```sh
nix store prefetch-file --unpack https://download.jetbrains.com/toolbox/jetbrains-toolbox-VERSION.tar.gz
```
