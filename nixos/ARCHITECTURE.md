# Ownership and module plan

The goal is one set of preferences across Linux distributions without installing
another distribution's desktop through Home Manager.

| Layer | Responsibility | Entry point |
| --- | --- | --- |
| Feature composition | Group related Home Manager and NixOS modules | `modules/*.nix` |
| Dotfiles | Shell aliases, Git, Kitty, Yazi and application preferences | `modules/dotfiles.nix` |
| Editors | LazyVim, VSCodium, extensions and private editor dependencies | `modules/editors.nix` |
| Desktop preferences | Noctalia/Umbriel files, application themes and associations | `modules/desktop.nix` |
| Applications | Install desktop/CLI applications and native user services on NixOS | `modules/applications.nix` |
| Login | Install and configure the privileged Noctalia Greeter | `modules/greeter.nix` |
| Native distribution | Install applications, compositor, portals, drivers and login services | `native/README.md` |

## Design iterations

1. Splitting only the old import list leaves package installation, services and
   configuration coupled inside Home Manager modules. Separate these responsibilities.
2. Suppressing `home.packages` globally would silently hide future accidental
   installations. Instead use upstream `package = null` for configuration-only
   modules, and plain dotfiles when a module cannot operate without its package.
   Noctalia/Umbriel use their official Home Manager modules with null packages
   and services disabled, retaining upstream config generation.
3. Installing language tools globally on another distribution creates competing
   toolchains. Put editor dependencies in the editor wrappers; project environments
   and native command-line tools remain independent.
4. Desktop setup must not block a dotfile rebuild or assume a compositor exists.
   Keep palette initialization in the explicit `desktop-apply` command. NixOS runs
   it from a native user unit at graphical login; Debian/Fedora installers provide
   an equivalent native unit after installing the desktop.
5. Keep feature composition explicit through flake-parts' typed `flake.modules`.
   Leaf implementations stay in `home/` and `system/`; package helpers, assets and
   tests are ordinary files rather than auto-imported modules. Adding a helper
   cannot accidentally enable a feature.

## Profiles

- `homeConfigurations.oad`: shared dotfiles and both editors. Does not install
  shell/CLI programs, a compositor, shell, greeter, portals or user services.
- `homeConfigurations.oad-desktop`: also writes desktop dotfiles and enables the
  Noctalia editor themes. Still installs only the editors. Install the desktop
  through the native package manager first.
- `nixosConfigurations.nixos`: native NixOS system/application/service modules
  plus Home Manager dotfiles and editors.

The root `nixos-setup.sh`, `debian-setup.sh` and `fedora-setup.sh` are entry points.
Native package lists live in `native/debian.sh` and `native/fedora.sh`, with shared
service setup in `native/common.sh` and TOML merging in `native/configure.py`.
NixOS copies its generated hardware file before evaluation; Git ignores that
file. Use `path:` flake references so local hardware participates in rebuilds.

Names and identity come from `profile.nix`. `stateVersion` remains unchanged.
Editor libraries, plugins, tools and Home Manager's internal activation utilities
remain Nix dependencies; “only editors” refers to applications installed into the
Home Manager package profile, not to every dependency in the Nix store.

## Verification

Evaluate all profiles with a second identity and paths containing spaces/quotes.
Assert that Home Manager's package list contains only the two editor packages and
its session-variable utility, and that it has no user services or timers. Verify
native command references, the opt-in desktop profile, generated configs, notebook
integration, activation-file migration, and update/bootstrap routing. Build or run
tests that exercise behavior; live graphics and display-manager changes need a
real-machine login test.
