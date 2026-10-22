# Configuration and deployment

Feature modules in `modules/` compose typed Home Manager and NixOS modules through
flake-parts. `home/` contains dotfile/editor implementations; `system/` contains
native NixOS integration; `system/applications/` installs general applications.
See [ARCHITECTURE.md](ARCHITECTURE.md) for ownership boundaries and design decisions.

## Profiles

Set identity, output names and checkout path in `profile.nix`. The examples use
its shipped defaults. Identity is explicit and is not inferred from environment
variables during evaluation. Keep `home.stateVersion` and `system.stateVersion`
at their existing values.

```sh
# NixOS: complete native system plus dotfiles/editors.
nix build path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel

# Another distribution: shared dotfiles and both editors.
nix build path:./nixos#homeConfigurations.oad.activationPackage

# Also configure an independently installed native Noctalia/Umbriel desktop.
nix build path:./nixos#homeConfigurations.oad-desktop.activationPackage
```

`bootstrap.sh` builds before activation, checks identity/architecture and validates
the NixOS root/boot filesystems against the configured hardware. It does not pull
or reset existing checkouts, rewrite hardware files, install a native desktop or
enable host services on another distribution.

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate
# Non-NixOS desktop dotfiles, after native application installation:
bash nixos/bootstrap.sh --repo-dir "$PWD" --profile oad-desktop --activate --backup-extension bak
```

## Ownership

| Files | Responsibility |
| --- | --- |
| `modules/profiles.nix` | Assemble portable, desktop and workstation profiles |
| `modules/editors.nix` | LazyVim/VSCodium, plugins, extensions, private toolchains |
| `modules/dotfiles.nix` | Shell, terminal, Git and tool preferences |
| `modules/desktop.nix` | Desktop dotfiles and native NixOS desktop integration |
| `modules/applications.nix` | NixOS packages and native user services |
| `modules/greeter.nix` | Official Noctalia Greeter NixOS module |
| `system/base.nix` | Account, boot, locale and integrated Home Manager |
| `system/networking.nix` | NetworkManager, Tailscale and firewall |
| `system/nix.nix` | Nix build limits, cache and garbage collection |
| `system/performance.nix` | Kernel, LAVD, power profiles and zram |
| `hardware*.nix` | Laptop-specific devices, disks, NVIDIA and PRIME |
| `native/` | Native application installation on other distributions |
| `pkgs/` | Packaging and executable helpers |
| `assets/` | Wallpapers, CSS and tablet seed |

Home Manager installs only the editors, their dependencies and its internal
session-variable helper. Dotfile generators use `package = null` where supported;
other preferences are ordinary files. Native commands are resolved through PATH.
No Home Manager user services or timers own desktop processes. NixOS provides
native user units for KDE Connect, Bluetooth media controls and desktop setup.

NixOS and integrated Home Manager share a package set. Noctalia/Umbriel retain
upstream's independent package sets for native dependencies and caches. Fonts,
GTK/Qt libraries, portals, drivers, login services and desktop applications are
installed outside Home Manager.

## Editors and notebooks

LazyVim supplies plugins, parsers, language servers, debug adapters and runtimes
through its wrapper. VSCodium uses explicit tool paths and a wrapper for its
terminal tools. On NixOS it retains the FHS launcher for PlatformIO; on other
distributions it uses ordinary VSCodium. Neither changes the host's global Rust,
Python, Node or C toolchain.

```sh
uv add --dev ipykernel
notebook-kernel
```

The helper registers the nearest project's `.venv`, preserves its interpreter
path and never installs project dependencies. In VSCodium select **Select Another
Kernel → Jupyter Kernels → Python (project .venv)**. Existing saved Python
interpreter selections may need **Python: Select Interpreter** once; the default
`.venv` hint does not override a cached selection. In LazyVim use `<leader>mp` for
the project kernel or `<leader>mi` for the Nix fallback.

Python analysis is basic and limited to open files. Ruff remains enabled.
Neovim keeps diagnostic signs/underlines; `<leader>cd` and `<leader>xx` show
details and `<leader>uv` toggles inline text. Xournal++ is installed by the NixOS
application module for tablet notes and PDF annotation.

## Desktop state

Noctalia preferences are TOML generated from Nix; wallpaper, palette algorithm and
mode remain writable runtime choices. `desktop-apply` seeds only missing app
palettes, builds Bat's cache with the installed native Bat, and reconciles managed
preferences. NixOS runs it at graphical login. On another distribution run it
explicitly after native app installation and after changes to desktop preferences.
It also reapplies the managed Thunar volume preferences when native xfconf is
available. It is never a Home Manager activation hook. The greeter's wallpaper/color sync
remains Noctalia's **Security → Noctalia Greeter → Auto-Sync / Sync Now** feature.

## Migration

Apply from a TTY or another session when moving away from old Home Manager-owned
session services; Home Manager may stop removed units during migration. Log in
again to clear old environment variables. The new generation links dotfiles and
removes obsolete managed package links; it does not uninstall native packages or
purge untracked home files. Back up unmanaged conflicts with bootstrap's
`--backup-extension bak` on standalone Home Manager.

On NixOS, Flatpaks move to the native NixOS nix-flatpak module and a system
installation. Existing user Flatpaks and their data are not removed automatically.
After the first successful update, inspect duplicates with:

```sh
flatpak list --user --app
flatpak list --system --app
```

After verifying the system copies work, optionally uninstall only duplicate user
apps without `--delete-data`. No blanket cleanup is enabled. NVIDIA GL extensions
follow the loaded driver through Flatpak; reboot after changing drivers before
updating those extensions.

The `up` and `update` commands on standalone Linux use the selected Home Manager
profile, including `oad-desktop`. The pinned manager CLI runs through `nix run`;
no global manager package is installed. Native system/application updates stay
with the distribution. On NixOS, `update` retains `nh os switch` and activation
logs, followed by Flatpak updates.

## Checks

```sh
nix flake check path:./nixos --no-build --no-write-lock-file
nix build path:./nixos#checks.x86_64-linux.portability
```

Checks cover all profiles and an alternate identity, package/service boundaries,
native command routing, editor settings, desktop initialization, file migration,
plugins and updater behavior. The NVIDIA module and greeter are separate build
checks because evaluation cannot catch compilation failures. Actual display,
GPU/suspend, greeter and VSCodium GUI behavior need real-machine testing.
