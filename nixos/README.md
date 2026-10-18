# Desktop configuration

One shared Home Manager desktop runs on NixOS or an existing Debian/Fedora
installation. `profile.nix` contains identity and deployment paths;
`hardware.nix` and the generated `hardware-configuration.nix` describe the laptop.

## Where settings belong

| Location | Owns |
| --- | --- |
| `configuration.nix` | NixOS entry point and original state version |
| `system/base.nix` | Boot, locale, user account, Home Manager wiring, journal limits |
| `system/networking.nix` | NetworkManager, Tailscale and KDE Connect firewall policy |
| `system/nix.nix` | Nix build limits, cache, garbage collection and optimisation |
| `system/desktop.nix` | Login sessions, portals, host privileges, audio, printing/scanning and power |
| `system/development.nix` | Docker, foreign-binary loader and PlatformIO device rules |
| `system/gaming.nix` | GameMode privileges and Steam device integration |
| `home/apps.nix` | Browser, chat, office, media viewers, image editors and scanner UI |
| `home/files.nix` | Thunar/plugins, archives, removable drives, user folders and file associations |
| `home/engineering.nix` | Blender, FreeCAD, Logisim, WinBoat and webOS tools |
| `home/kitty.nix` | Declarative terminal settings, shortcuts and migration |
| `home/terminal.nix` | Command-line utilities/diagnostics |
| `home/noctalia-settings.nix` | Shell preferences and bar layout |
| `home/desktop.nix` | GTK/Qt, fonts/icons, KDE Connect and Bluetooth media integration |
| `home/capture.nix` | Screenshot, recording, OCR and annotation dependencies |
| `home/displays.nix` | Display controls and laptop mirroring |
| `home/development/` | Editors, shared language/build tools, Git and GitHub CLI |
| `home/gaming.nix` | Steam/Millennium, game launchers and GameMode user daemon |
| `home/linux.nix` | Standalone Linux portals and graphics integration |
| `pkgs/` | Package fixes and scripts that genuinely require wrappers or migrations |
| `assets/` | Wallpapers/avatar, palette template, browser CSS and tablet profile seed |

Import lists are explicit. Modules use ordinary Nix attributes, lists and
conditionals; there is no auto-import framework, custom option tree or overlay
layer. Add applications to their functional module and let native services
remain in `system/`. Hardware pins and state versions stay unchanged.

Home Manager declares how assets are installed or rendered. The tablet JSON
seeds calibration on first use; later activations update its auxiliary bindings
while preserving calibration and unrelated profiles. Palette and CSS files stay
in their native formats. No parallel `dotfiles/` configuration tree is used.

## Desktop coverage

- **Files:** Thunar with archive/removable-drive plugins, File Roller, modern
  7-Zip, ZIP utilities, GVfs/MTP/SSH mounts, trash and thumbnails. Standard home
  folders are created, and PDFs, images, archives and media have explicit handlers.
- **Work:** Zen, Discord, LibreOffice with English spellchecking, Xournal++,
  Papers, Simple Scan, a printer-settings UI, GIMP and Inkscape.
- **Media:** mpv and imv, English/Arabic OCR, Swappy, Screen Toolkit capture and
  recording, Bluetooth media keys, PipeWire and PulseAudio-client compatibility.
- **Development:** VSCodium, Neovim, language servers/runtimes, Make/CMake/Ninja,
  pkg-config, Git LFS, GitHub CLI, PlatformIO and project development shells.
- **Engineering/gaming:** Blender with laptop NVIDIA offload, FreeCAD, Logisim,
  Steam/Millennium and ProtonPlus; OrcaSlicer remains a user Flatpak.
- **Diagnostics:** btop, USB/PCI/storage tools, lsof/strace, sysstat, DNS lookup,
  nmap, iperf3, MTR, ethtool, curl/wget and rsync. Privileged operations still
  require the native host's permissions or sudo.

ProtonPlus is the one installed Proton-version manager. Swappy is the one
installed screenshot annotation editor. Rnote, protonup-ng and Satty are absent.
The two recording backends remain because Screen Toolkit actively supports
fallback between them. GNOME remains an alternative login session.

On NixOS, CUPS, IPP-over-USB, SANE/airscan and mDNS discovery provide print/scan
support. CUPS sharing stays disabled; mDNS discovery uses its standard UDP port.
MTR uses the native capability wrapper for unprivileged network diagnostics.
On standalone Linux, Home Manager installs the user tools only: the distribution
must supply audio, CUPS, Avahi, SANE/airscan, device rules, PAM and GPU drivers.
The existing bootstrap host-setup command previews a minimal native baseline;
it does not configure every optional desktop service.

## Validate and deploy

Run from the repository root:

```sh
(cd nixos && nix fmt)
nix flake check path:./nixos
nix build path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake path:./nixos#nixos
```

For standalone Linux:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate
```

Review `profile.nix` and hardware before deploying to another machine. A
`path:` reference includes new files before Git tracks them. Declared Noctalia
preferences take precedence at activation; migration backups retain the previous
settings. Wallpaper/theme mode remain runtime state.

Update inputs deliberately and build before activating:

```sh
nix flake update nixpkgs home-manager --flake path:./nixos
nix build path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel --no-link
```

The Noctalia updater also builds before asking to switch. Failed or declined
updates leave the lockfile for inspection. Independent Noctalia, Umbriel and
Millennium pins preserve binary-cache and runtime compatibility.

## Everyday commands

The same names work in Bash and Zsh on both backends:

| Command | Action |
| --- | --- |
| `cconf` | Enter the configuration directory |
| `cnf` | Open the module tree in `$EDITOR` |
| `neval` | Evaluate the flake without building checks |
| `ncheck` | Run the complete flake checks |
| `nbuild` | Build the selected NixOS/Home Manager profile without activation |
| `up` / `rebuild` | Build and switch through nh, with a package diff |
| `update` | Update flake inputs, build and switch, then update user/system Flatpaks |
| `nupdate` | Refresh the lockfile only; inspect/build before switching |
| `nfmt` | Format the configuration tree without changing the shell's directory |

Eza supplies the standard listing aliases; `lt` limits the tree to two levels.
The formatter uses upstream `nixfmt-tree`, so `nix fmt` formats repository files
instead of waiting for standard input. Game launchers accept `--` before a
command. `update` works from any directory and uses the declared NixOS host or
standalone Home Manager profile. It runs `nix flake update`, then `nh os switch`
or `nh home switch`, then `flatpak update --noninteractive --assumeyes`. nh builds
before activation and shows the generation diff. Nix failures stop later stages;
a Flatpak failure reports that Nix was already activated. The lockfile remains
available for inspection after a build failure.

On NixOS, Noctalia uses the same command and private update lock. `update` proceeds without
an extra confirmation; normal privilege authentication can still be required.
On standalone Linux it updates Home Manager and Flatpaks; native host packages
remain the distribution's responsibility. `up`/`rebuild` apply the current
lockfile, while `nupdate` only refreshes inputs.

## Resource policy and package fixes

Nix runs at most two local builds with four cores per build. Weekly collection
retains the existing 30-day generation policy; low-space collection starts below
1 GiB and aims for 5 GiB free without deleting live roots. Scheduled maintenance
runs at low CPU/I/O priority. Journals and Docker build cache remain bounded;
weekly SSD TRIM is already a NixOS default.

Application-specific insecure-package exceptions remain in
`package-policy.nix`, outside the system package set. WinBoat currently needs
its explicit Electron exception. The temporary Toolbox and version-specific
Zen download fixes are isolated in `pkgs/`; remove them when their locked
upstream packages no longer need them. Driver, suspend, monitor and printer
behavior still requires testing on actual hardware.

## Editor workflows

Both editors use the repository's `.editorconfig` and shared Nix CLI tools.
Each owns its language-client, environment, test and debugger integrations.
VSCodium uses extension-bundled servers where appropriate; basedpyright and
Ruff prefer versions installed in the selected Python environment, and Prettier
prefers the project's installation. Their Nix-owned extension bundles provide
fallbacks. Neovim uses Nix-supplied servers/adapters; Conform resolves local
Prettier first, then the CLI fallback. clangd, gopls, rust-analyzer and Nix tools
retain explicit shared paths/settings where needed.

Python defaults to a project's `.venv`; create/sync it with uv
and include pytest in the project's development dependencies. The separate
**Python (Nix notebooks)** Jupyter kernel is registered declaratively.

- LazyVim: `<leader>db` sets a breakpoint, `<leader>dc` starts/continues,
  `<leader>du` opens the debugger, and `<leader>dr` lists Rust debuggables in a
  Rust buffer. `<leader>tr` runs the nearest test, `<leader>tt` the file,
  `<leader>tT` all test files, and `<leader>ts` opens the test summary. Python,
  Go and Rust adapters are enabled. `<leader>cv` selects a Python environment.
- VSCodium: F5 uses a Python-file or Go-package preset, or a project's
  `.vscode/launch.json`; the Testing view runs pytest; Go/Rust code lenses run
  their project tests.
  CodeLLDB supplies C/C++ and Rust debugging. `Ctrl+Alt+O` opens an OpenCode
  terminal at the workspace. LazyVim's `<leader>ao` toggles its reusable project
  terminal, `<leader>aa` asks with the current selection/cursor context, and
  `<leader>as` opens actions for diagnostics, explanations and diff review.
  Save files before sharing context. Authenticate with `opencode auth login`.
- Python formatting uses Ruff; Go uses gofumpt/Staticcheck; Rust uses
  rust-analyzer/Clippy. Golangci-lint remains an explicit project command rather
  than another save-time diagnostic worker. ESLint and Prettier use project
  configuration. Language-specific workspace settings can override defaults.
  Ruff owns Python import actions in both editors; basedpyright handles type
  analysis and navigation. Routine Ruff protocol tracing is disabled.
- Dependency/output trees are excluded from VSCodium file watching. Python
  reports diagnostics for open files; test discovery on every save is disabled.
  Debug/test plugins load on demand and Nix owns every plugin and adapter.

LazyVim also includes surround editing (`gsa`, `gsd`, `gsr`), yank history
(`<leader>p`, `[y`/`]y`) and Diffview (`<leader>gD`, file history with
`<leader>gH`, close with `<leader>gq`). These complement the existing Snacks
picker, explorer, terminal, TODO search and Git tools. VSCodium adds TODO Tree
and GitHub Pull Requests, plus Jupyter keymaps and rich output renderers.

Open an existing `.ipynb` in LazyVim to edit its Markdown/code representation;
Jupytext writes the notebook back on save. Molten registration is built by Nix.
Start **Python (Nix notebooks)** with `<leader>mi`, or choose another installed
kernel with `<leader>mI`. Starting restores stored outputs without running code.
Use `<leader>mc` for the current cell, `<leader>ma` through the current cell,
`<leader>mb` from the current cell down, and `<leader>mA` for all Python cells.
`<leader>mo` enters output, `<leader>mh` hides it, `<leader>mx` interrupts and
`<leader>mq` stops the kernel. Outputs are saved with the notebook once a kernel
is attached. Kitty displays image outputs; text execution also works headlessly.
Quarto/Otter supplies Python completion and diagnostics within Markdown cells;
the Quarto publishing CLI is separate from this notebook workflow.

VSCodium uses the same named Nix kernel. Select it in the notebook kernel picker;
project environments need their own `ipykernel` and project dependencies. Both
editors retain project-specific kernels and dependencies rather than adding
every scientific package globally. Jupyter's usual `Shift+Enter` and
`Ctrl+Enter` bindings are available in VSCodium, with scrollable output.

`editor-integration` checks notebook conversion, cell support, kernel discovery
and source/output preservation. `editor-notebooks` additionally starts a local
kernel, executes an edited cell and checks saved results. The latter needs local
socket access; restricted execution environments can block Jupyter communication.

The built-in debugger understands standard Python/LLDB entries in workspace
`launch.json`. VS Code extension-specific launch features can still require the
extension's own UI.

## Declarative desktop and shortcuts

Use `home/kitty.nix` for terminal behavior, `home/noctalia-settings.nix` for shell
preferences, and `home/umbriel.nix` for window rules and desktop bindings.
Noctalia keeps the palette, last wallpaper and theme mode as runtime data;
declared preferences win on rebuild with backups of prior overrides.

The bar places launcher/workspaces on the left, clock in the center and status
controls on the right. It reserves space instead of covering tiled windows.
Disabled, connector-specific desktop/lockscreen widget layouts are omitted.
Umbriel starts in dwindle; its cycle contains only dwindle and scrolling.
Scrolling centers when adjacent windows cannot fit; manual dwindle splits stay
stable. Kitty opacity is configured once, rather than multiplied by a second
compositor opacity rule.

[SHORTCUTS.md](SHORTCUTS.md) lists daily controls. `Mod+S` opens Screen Toolkit;
`Mod+Shift+S` enters capture shortcuts; `Mod+Ctrl+S` opens settings;
`Mod+Shift+Escape` shows Umbriel's actual live bindings.

The next useful upgrades are encrypted backups of home data, project-specific
`.envrc`/development shells using the existing direnv integration, and CI checks
for configuration/input updates. Measure boot/session performance before changing
drivers or schedulers. Nix recreates software; it does not back up
personal documents, browser profiles or credentials.
