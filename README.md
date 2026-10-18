# Desktop configuration

A NixOS desktop with integrated Home Manager, plus portable shell and development
tools for Debian/Fedora. Each operating system owns its desktop services.

| Profile | Owns |
| --- | --- |
| NixOS | Umbriel, portals, drivers, services and privileged helpers through NixOS modules |
| NixOS Home Manager | Personal applications, Kitty/Noctalia settings, editors, themes and shortcuts |
| Standalone Home Manager | Bash/Zsh, Neovim/LazyVim, Git, language/build tools, Jupyter and direnv |

The standalone profile keeps the distribution's GUI applications, MIME defaults,
GTK/Qt settings and GPU environment. It installs no Nix compositor or portal stack.
NixOS and its integrated Home Manager share the same package set.

## Configure and deploy

Edit [nixos/profile.nix](nixos/profile.nix) for your account, checkout and output
names. The shipped defaults are user `oad`, home `/home/oad`, flake directory
`~/config/nixos`, and NixOS host `nixos`. Hardware files are specific to this
laptop; review them before deploying NixOS elsewhere. Keep state versions unchanged.

With Nix installed, run from the checkout:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate
```

NixOS builds the full system. Other Linux distributions build the portable tools
profile. Bootstrap checks identity, preserves existing checkout changes and builds
before activation. Use `--backup-extension bak` with standalone activation to
back up conflicting unmanaged files. `--install-nix` shows official installation
instructions if Nix is absent.

For the first migration from the old shared desktop profile, use a native desktop
session or a TTY: removing its managed units can stop Umbriel. Log in again after
switching to clear the old session environment. The old Debian installer no longer
installs a desktop or changes host services. Existing native host changes need
separate review; see [migration details](nixos/README.md#moving-from-the-old-standalone-desktop).

## Daily use

- `up` / `rebuild`: apply the selected system or Home Manager configuration.
- `update`: update flake inputs, build/switch, then update Flatpaks if installed.
- `ppt2pdf` / `ppt2txt`, `doc2pdf` / `doc2txt`, `xls2csv`: batch Office conversions.
- `cconf` / `cnf`: enter or edit the configuration directory.
- `zdev` / `za` / `zl`: open a development workspace, attach or list Zellij sessions; `y` browses files with Yazi.
- `neval` / `ncheck` / `nbuild` / `nfmt`: evaluate, check, build or format.

Full module map, editor/notebook workflows, desktop theming, Steam maintenance,
plugin patches and recorded hardware observations are in
[nixos/README.md](nixos/README.md). Desktop bindings are in
[nixos/SHORTCUTS.md](nixos/SHORTCUTS.md).
Upstream app templates and terminal workspace setup are documented in
[nixos/THEMING.md](nixos/THEMING.md).

## Validation

```sh
nix flake check path:./nixos
nix build --no-link path:./nixos#homeConfigurations.oad.activationPackage
nix build --no-link path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel
```

Checks cover profile separation, desktop integration, both editor configurations,
state migrations, update/bootstrap behavior, Kitty parsing and dark/light templates.
Builds do not activate the host; graphical logins and hardware still require a
live test.
