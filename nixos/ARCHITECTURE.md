# Ownership and module plan

The goal is one set of preferences across Linux distributions. NixOS installs
applications through Nix; other distributions use native application installation
and Home Manager writes their dotfiles only.

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
3. On NixOS, keep editor dependencies in their Nix wrappers. On other distributions,
   do not install editors, plugins or language tools through Nix: share settings,
   resolve native commands through PATH, and let Lazy/Mason/Codium manage tools.
   Project environments remain independent on both backends.
4. Desktop setup must not block a dotfile rebuild or assume a compositor exists.
   Keep palette initialization in the explicit `desktop-apply` command. NixOS runs
   it from a native user unit at graphical login; Debian/Fedora installers provide
   an equivalent native unit after installing the desktop.
5. Keep feature composition explicit through flake-parts' typed `flake.modules`.
   Leaf implementations stay in `home/` and `system/`; package helpers, assets and
   tests are ordinary files rather than auto-imported modules. Adding a helper
   cannot accidentally enable a feature.

## Profiles

- `homeConfigurations.oad`: all six applications' dotfiles, no applications.
- `homeConfigurations.oad-desktop`: compatibility selector with the same full
  dotfile scope; its aliases preserve this output name.
- `nixosConfigurations.nixos`: native NixOS application/service modules plus
  Home Manager dotfiles and Nix-packaged editors/private dependencies.

The root `nixos-setup.sh`, `debian-setup.sh` and `fedora-setup.sh` are entry points.
Native package lists live in `native/debian.sh` and `native/fedora.sh`, with shared
service setup in `native/common.sh` and TOML merging in `native/configure.py`.
NixOS copies its generated hardware file before evaluation; Git ignores that
file. Use `path:` flake references so local hardware participates in rebuilds.

Names and identity come from `profile.nix`. `stateVersion` remains unchanged.
Editor libraries/plugins/tools are Nix dependencies on NixOS only. Standalone
profiles contain only Home Manager's internal session helper. Rendering helpers
and source assets used to generate dotfiles can still have Nix build dependencies;
they do not install the six application binaries.

## Verification

Evaluate all profiles with a second identity and paths containing spaces/quotes.
Assert that standalone profiles contain only the session-variable utility, while
NixOS installs both editors. Neither profile owns user services or timers. Check
that native editor settings contain no Nix executable paths. Verify
native command references, the opt-in desktop profile, generated configs, notebook
integration, activation-file migration, and update/bootstrap routing. Build or run
tests that exercise behavior; live graphics and display-manager changes need a
real-machine login test.
