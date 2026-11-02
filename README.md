# Desktop configuration

One entry point for the NixOS workstation and a shared home on Fedora/Debian:

```sh
nix run github:OmarDardery/config
```

Nix must already be installed. Run as your normal user. If flakes are not enabled:

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

| Host | Applies |
| --- | --- |
| NixOS | Full system, applications, services and Home Manager |
| Fedora / Debian | Home Manager applications and dotfiles |

The launcher clones to `~/config`, detects your account, writes ignored local
identity and builds before activating. NixOS copies generated hardware from
`/etc/nixos/hardware-configuration.nix` if missing, then uses sudo to switch.
Standalone dotfile conflicts get unique `before-config-*` backups; the NixOS
Home Manager module retains its `.bak` policy. Writable editor settings survive.

**The full NixOS configuration targets the ASUS TUF A14, x86_64, UEFI.** Review
[nixos/hardware.nix](nixos/hardware.nix) before using different hardware: it has
NVIDIA/PRIME bus IDs and a storage mount. Preserve system/home state versions.
Fedora/Debian retain their desktop, login manager, kernel drivers and file
associations. This launcher runs no apt/dnf commands or native desktop installer.

## Home profiles

Home Manager installs LazyVim/Neovim, VSCodium with Nix and EditorConfig extensions,
direnv/nix-direnv and the editor font in development profiles. Language toolchains
are loaded only through project shells. NixOS retains themed native Steam and its
Millennium helpers; NixOS handles graphics, controllers and GameMode. Other Linux
hosts get declarative **user Flatpak Steam** and a `steam` command, without sudo.
Its initial network installation runs during activation; failed downloads fail the
apply visibly. A user service retries on login, and a user timer handles updates.
Existing native Steam data is preserved; add an existing library through Storage
settings if needed. The Flatpak client does not receive NixOS Millennium hooks.

| Profile | Includes |
| --- | --- |
| `default` | Core settings, editors, direnv and Steam; preserves the distro desktop |
| `core` | Shell, Git, Yazi settings and configuration maintenance helpers |
| `dev` | Core plus editors, direnv and font; no Steam |
| `gaming` | Core plus Steam; no editors or desktop theme |
| `desktop` | All above plus Umbriel, Noctalia, Kitty and desktop preferences |

```sh
nix run github:OmarDardery/config -- --profile dev
# On NixOS, select a home-only profile explicitly:
nix run github:OmarDardery/config -- --home --profile dev
```

Subsequent home applies remember your selection. `--profile default` resets it.
Full output names are `<username>`, `<username>-core`, `<username>-dev`,
`<username>-gaming` and `<username>-desktop`. The full NixOS system keeps its
laptop desktop. Home Manager supplies preferences for Umbriel/Noctalia in the
optional desktop profile; install/start those apps through the distro outside
NixOS. Log out/in so shells and launchers see home packages and Flatpak exports.

## Graphics outside NixOS

Codium uses Home Manager's NixGL integration. The default vendor-neutral Mesa
wrapper suits Intel/AMD and this laptop's AMD-driven desktop. Libraries are scoped
to the application; no kernel driver or `/run/opengl-driver` changes are made.
Steam Flatpak manages its graphics runtimes independently. Child processes inherit
NixGL's library environment: if a native tool launched from Codium reports symbol
errors, run it from a regular terminal or the project's Nix shell.

For an NVIDIA-only desktop, create ignored `nixos/local-gpu.nix`:

```nix
{
  backend = "nvidia";
  nvidiaVersion = "<exact host driver version>";
  nvidiaHash = "<hash from nix store prefetch-file>";
  nvidiaAcceptLicense = true; # Set after reviewing the driver license.
}
```

Get the version using `nvidia-smi --query-gpu=driver_version --format=csv,noheader`.
Prefetch the matching official archive with
`nix store prefetch-file --json https://download.nvidia.com/XFree86/Linux-x86_64/VERSION/NVIDIA-Linux-x86_64-VERSION.run`.
Use its `hash` in the local file, then apply. Update the pin whenever the host
NVIDIA driver changes. Explicit pins keep evaluation pure, without `--impure`.
The optional libraries require accepting NVIDIA's
[driver license](https://www.nvidia.com/content/DriverDownloads/licence.php?lang=us).
This setting never installs or replaces the host kernel driver.

## Deployment options

```sh
# Fork or another checkout location
nix run github:OmarDardery/config -- YOURNAME/config --repo-dir ~/dotfiles
# Build without activating
nix run github:OmarDardery/config -- --build-only
# Apply from an existing clone
cd ~/config
bash setup.sh
```

Repository arguments accept `OWNER/REPO`, `github:OWNER/REPO` or an HTTPS GitHub
URL and require this root flake/profile layout. Existing checkouts are never
pulled, reset or switched. Use `git pull --ff-only` yourself before applying.
`--ref` chooses a branch/tag/commit only for a new clone. Test an unmerged version
with `nix run github:OmarDardery/config/BRANCH -- --ref BRANCH`; use a fresh
`--repo-dir` if `~/config` already exists.

Personal defaults remain in [nixos/profile.nix](nixos/profile.nix). The generated
`nixos/local-profile.nix` supplies account, home, checkout and selected output.
It and generated hardware stay ignored; `path:` builds include them without
staging. The legacy distro setup scripts and `nixos/bootstrap.sh` now forward to
this same launcher.

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

Everyday NixOS apps and Steam stay enabled. Specialist bundles default off;
set `workstation.engineering.enable`, `containers.enable`, `printing.enable` or
`diagnostics.enable` in [nixos/configuration.nix](nixos/configuration.nix) as needed.
Diagnostics covers host hardware/storage/network tools. Containers enables
socket-activated Docker. WinBoat and its insecure Electron exception are removed.
User data and unmanaged Flatpaks are retained. Editors keep Mason, Tree-sitter
compilation, notebook kernels and provider language runtimes disabled; tools live
in the dev shells. LazyVim downloads plugins on first use. Settings/plugins remain
writable and user-owned, with no separate native editor installer.

`up`/`rebuild` apply; `nbuild` builds only; `update` updates inputs, applies, then
updates Flatpaks. `neval` checks the relevant system/home; `cnf`/`cconf` edit/enter
the root checkout. `desktop-apply` initializes palettes in the desktop profile.

NixOS recovery: `sudo nixos-rebuild switch --rollback` or a previous boot generation.
List standalone generations with `nix run path:./#home-manager -- generations` and
run a previous generation's `activate` script. Mutable editor files/backups need
manual restoration if you want to undo their one-time initialization.

[Detailed notes](nixos/README.md) · [Shortcuts](nixos/SHORTCUTS.md) ·
[Theming](nixos/THEMING.md) · [Backups](nixos/BACKUPS.md)
