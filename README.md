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
missing. It builds the complete system before using sudo to switch, including
Home Manager. `#update` updates the local `flake.lock`; it preserves your source
edits and does not pull Git commits. Pull source changes with `git pull --ff-only`
when wanted, then apply. Review and commit lockfile changes in your checkout.

**This NixOS host targets an ASUS TUF A14, x86_64, UEFI.** Review
[nixos/hardware.nix](nixos/hardware.nix) for another machine: it contains
NVIDIA/PRIME bus IDs and a storage mount. Preserve system/home state versions.

NixOS manages applications and desktop services declaratively. Home Manager
configures the shell, Git, editors, Umbriel, Noctalia and desktop preferences.
Neovim/LazyVim, VSCodium, direnv and native Steam/Millennium remain available;
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
The distro-specific setup scripts forward to the matching flake.

NixOS personal defaults are in [nixos/profile.nix](nixos/profile.nix).
Generated `nixos/local-profile.nix` and hardware stay ignored; `path:` builds
include them without staging. The native dotfile installer never writes them.

## Development shells and project templates

```sh
# From a project directory, use a convenience shell:
nix develop ~/config#python
nix develop ~/config#go --command codium .
```

| Shell | Tools |
| --- | --- |
| `default` | Nix language server/formatter and common build utilities |
| `python` | Python, uv, Ruff, Pyright |
| `go` | Go, gopls, Delve, golangci-lint |
| `node` | Node.js, pnpm, TypeScript language server |
| `rust` | Rust, Cargo, rustfmt, Clippy, rust-analyzer |
| `cpp` | C/C++ compiler, clang tools, CMake, Ninja, GDB |

All shells have Git, Make and pkg-config. Nix/Node shells omit the C compiler;
others include it for linking/native dependencies. Python pins uv to Nix's
interpreter and disables automatic interpreter downloads. Create the virtual
environment inside the shell:

```sh
uv venv
uv pip install -r requirements.txt
source .venv/bin/activate
codium .
```

Recreate `.venv` if it came from a different distro/interpreter. Project packages
are not installed automatically. Close existing Codium processes before launching
from a shell so extensions/terminals inherit its environment. Install language
extensions or LazyVim extras per your projects.

For automatic loading, use `use flake "path:$HOME/config#python"` in the project's
`.envrc`, review it, then `direnv allow`. For a durable independent project:

```sh
# Inside a project directory without conflicting template files:
nix flake init -t github:OmarDardery/config#python
nix develop
```

Templates: `python`, `go`, `node`, `rust`, `cpp`, `nix`. Each includes a standalone
flake, editable `shell.nix`, `.envrc`, ignore rules and useful editor settings.
Commit its generated `flake.lock` so workstation updates do not change the project
toolchain. Convenience shells reuse these same definitions.

## Keep it lean

NixOS specialist bundles default off. Enable `workstation.engineering.enable`,
`containers.enable`, `printing.enable` or `diagnostics.enable` in
[nixos/configuration.nix](nixos/configuration.nix) as needed. Everyday apps and
Steam remain enabled. Docker is socket-activated when enabled. Existing user
data and unmanaged Flatpaks are retained.

Editor preferences stay writable. Mason, Tree-sitter compilation, notebook
kernels and language providers are disabled in the starter; add tools per project.
On NixOS, `up`/`rebuild` apply, `nbuild` builds only, `update` updates inputs and
switches, `neval` checks the flake, and `cnf`/`cconf` edit/enter the checkout.
`desktop-apply` initializes desktop palettes at graphical login.

NixOS recovery: `sudo nixos-rebuild switch --rollback` or a previous boot generation.
Mutable editor preferences need manual restoration from their backups.

[Detailed NixOS notes](nixos/README.md) · [Shortcuts](nixos/SHORTCUTS.md) ·
[Theming](nixos/THEMING.md) · [Backups](nixos/BACKUPS.md)
