# Desktop configuration

NixOS owns the desktop session and system services. Its integrated Home Manager
configuration owns personal applications and preferences. On Debian/Fedora, the
standalone profile supplies shell and development tools alongside the native
desktop. `profile.nix` contains identity and deployment paths;
`hardware.nix` and the generated `hardware-configuration.nix` describe the laptop.

## Where settings belong

| Location | Owns |
| --- | --- |
| `configuration.nix` | NixOS entry point and original state version |
| `system/base.nix` | Boot, locale, user account, Home Manager wiring, journal limits |
| `system/networking.nix` | NetworkManager, Tailscale and KDE Connect firewall policy |
| `system/nix.nix` | Nix build limits, cache, garbage collection and optimisation |
| `system/desktop.nix` | Umbriel session/portal module, Thunar/GVfs, Flatpak helper, login, audio, printing and power |
| `system/development.nix` | Docker, foreign-binary loader and PlatformIO device rules |
| `system/gaming.nix` | Upstream Steam and GameMode modules, including drivers, units and privileges |
| `home/default.nix` | Shared shell, Neovim, Git and development tools |
| `home/nixos.nix` | Full desktop user configuration for the NixOS host |
| `home/apps.nix` | Browser, chat, office, media viewers, image editors and scanner UI |
| `home/files.nix` | File preferences, archive/PDF tools, user folders and file associations |
| `home/engineering.nix` | Blender, FreeCAD, Logisim, WinBoat and webOS tools |
| `home/kitty.nix` | Declarative terminal settings, shortcuts and migration |
| `home/terminal.nix` | Command-line utilities/diagnostics |
| `home/noctalia-settings.nix` | Shell preferences and bar layout |
| `home/desktop.nix` | GTK/Qt, fonts/icons, KDE Connect and Bluetooth media integration |
| `home/capture.nix` | Screenshot, recording, OCR and annotation dependencies |
| `home/displays.nix` | Display controls and laptop mirroring |
| `home/development/` | Editors, shared language/build tools, Git and GitHub CLI |
| `home/gaming.nix` | Millennium setup/theme and game launchers |
| `home/linux.nix` | Portable tools; no desktop, portals, GPU overrides or GUI services |
| `pkgs/` | Package fixes and scripts that genuinely require wrappers or migrations |
| `assets/` | Wallpapers/avatar, palette template, browser CSS and tablet profile seed |

Import lists are explicit. Modules use ordinary Nix attributes, lists and
conditionals; there is no auto-import framework, custom option tree or overlay
layer. Add applications to their functional module and let native services
remain in `system/`. NixOS and Home Manager use the same `pkgs` through
`useGlobalPkgs` and `useUserPackages`. Hardware pins and state versions stay
unchanged.

Home Manager declares how assets are installed or rendered. The tablet JSON
seeds calibration on first use; later activations update its auxiliary bindings
while preserving calibration and unrelated profiles. Palette and CSS files stay
in their native formats. No parallel `dotfiles/` configuration tree is used.

## NixOS desktop coverage

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
On Debian/Fedora, use the distribution's desktop, graphical applications, GPU
drivers and services. The standalone profile configures Bash/Zsh, Neovim/LazyVim,
Git, command-line tools, language servers, runtimes, Jupyter tools and direnv.
VSCodium and JetBrains Toolbox belong to the NixOS desktop profile; Debian's
editors remain under its package manager. Project shells work on both systems.

### Moving from the old standalone desktop

For the first switch, log into the distribution's native desktop or a TTY
before activating the standalone generation. Removing the old managed services
can stop its Umbriel session. Then log out completely and log back in.
Home Manager removes its previous
managed desktop files and services; a fresh login clears the old session's
Qt/GIO/graphics environment. Runtime wallpaper/palette data and personal files
are retained. For the first NixOS ownership migration, use the GNOME fallback
or a TTY and start Umbriel again afterward. Inspect Home Manager's activation
output if a local edit or
conflicting file prevents cleanup.

The standalone profile no longer installs Umbriel, Noctalia, Steam, Flatpak,
portals or graphical user services, and does not change desktop MIME defaults,
GTK/Qt themes or GPU library paths. Install a native compositor/session through
the distribution separately if wanted. The former `--setup-host` installer was
removed; `debian-setup.sh` now forwards to the tools bootstrap beside the script
or in `~/config`. The flake and follow-up update commands use `~/config/nixos`.

If you used the old Debian installer, its APT packages, service settings and
udev rules remain native host configuration. After switching from a native
session, review the obsolete installer-created login entry
`/usr/share/wayland-sessions/umbriel-configs.desktop` and launcher
`/usr/local/bin/start-umbriel-configs`; remove those two if no longer needed.
The old GPU helper also installed `/etc/tmpfiles.d/non-nixos-gpu.conf` and
`/nix/var/nix/gcroots/non-nixos-gpu.conf`, which recreate `/run/opengl-driver`.
Review and retire those installer-created links when returning graphics entirely
to Debian; a reboot alone does not remove their configuration. The new profile
performs no privileged Debian desktop changes.

## Validate and deploy

Run from the repository root:

```sh
(cd nixos && nix fmt)
nix flake check path:./nixos
nix build path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake path:./nixos#nixos
```

For standalone Linux tools:

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

Noctalia uses the same update command as the shell. nh builds before activating;
failed updates leave the lockfile for inspection. Independent Noctalia, Umbriel and
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

LibreOffice shortcuts accept multiple files and `-o DIR` (default: the current
directory), and refuse to overwrite existing outputs:

```sh
ppt2pdf "Lecture 1.pptx" "Lecture 2.ppt" -o ~/Documents/PDF
ppt2txt *.pptx -o ~/Documents/Notes
doc2pdf report.docx
doc2txt report.docx
xls2csv budget.xlsx
```

`office2pdf` handles any supported Office document. `ppt2pptx`, `doc2docx`,
`xls2xlsx` and `xls2pdf` cover the other common conversions. The `ppt2*` aliases
also accept PPTX/ODP, `doc2*` accept DOCX/ODT, and `xls2*` accept XLSX/ODS.
Presentation text is extracted from LibreOffice's flat XML export in slide order;
it includes text boxes and tables, excludes speaker notes and masters, and does
not OCR images. CSV exports the active sheet with UTF-8 encoding. Each invocation
uses a temporary LibreOffice profile so an open GUI cannot intercept the command.
On NixOS LibreOffice is supplied by Nix; on Debian/Fedora these shortcuts use the
native LibreOffice installation, keeping the desktop owned by the distribution.

Eza supplies the standard listing aliases; `lt` limits the tree to two levels.
The formatter uses upstream `nixfmt-tree`, so `nix fmt` formats repository files
instead of waiting for standard input. Game launchers accept `--` before a
command. `update` works from any directory and uses the declared NixOS host or
standalone Home Manager profile. It runs `nix flake update`, then `nh os switch`
or `nh home switch`, then `flatpak update --noninteractive --assumeyes` when
Flatpak is installed. nh builds before activation and shows the generation diff. Nix failures stop later stages;
a Flatpak failure reports that Nix was already activated. The lockfile remains
available for inspection after a build failure.

On NixOS, Noctalia uses the same command and private update lock. `update` proceeds without
an extra confirmation; normal privilege authentication can still be required.
On standalone Linux it updates Home Manager and uses the native Flatpak command
if installed; native host packages remain the distribution's responsibility. `up`/`rebuild` apply the current
lockfile, while `nupdate` only refreshes inputs.

## Resource policy and package fixes

Nix runs at most two local builds with four cores per build. Weekly collection
retains the existing 30-day generation policy; low-space collection starts below
1 GiB and aims for 5 GiB free without deleting live roots. Scheduled maintenance
runs at low CPU/I/O priority. Journals and Docker build cache remain bounded;
weekly SSD TRIM is already a NixOS default.

The shared package policy is declared once in `package-policy.nix` and applied
to the NixOS system/integrated Home Manager package set. The standalone package
set reads the same policy. WinBoat currently needs its explicit Electron
exception. The temporary Toolbox and version-specific
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

The [theming/workspace guide](THEMING.md) lists supported apps, upstream template
sources, first-run behavior and the Zellij/Yazi workflow.

On NixOS, use `home/kitty.nix` for terminal behavior, `home/noctalia-settings.nix` for shell
preferences, and `home/umbriel.nix` for window rules and desktop bindings.
Noctalia keeps the palette, last wallpaper and theme mode as runtime data;
declared preferences win on rebuild with backups of prior overrides.

The floating bottom bar places launcher/workspaces on the left, date/time in the
center and status controls on the right. The bar and right-hand dock reserve no
space and hide on occupied workspaces; reveal them at their screen edges.
Screen Toolkit leads a tools group that expands on hover to show clipboard,
phone and Pomodoro controls. Their keyboard shortcuts work while collapsed.
The compact, centered launcher, restrained glass, soft shadows, 12-pixel corners
and 8-pixel window gaps use wallpaper-derived tonal colours across applications.
Volume, English/Arabic layout, graphical battery and active capture indicators are
visible in the bar. Notifications follow the focused monitor with at most three
toasts; the OSD sits at the top center. The dock shows apps on its current monitor.
A shared critically damped spring coordinates Umbriel transitions; opening/closing
uses a small 4% scale change. Two blur passes reduce rendering work, and hovering
partly hidden columns cannot unexpectedly scroll the strip. Type in `Mod+O`'s
overview to launch apps, or hold `Alt+Tab` to switch windows.
Disabled, connector-specific desktop/lockscreen widget layouts are omitted.
Umbriel starts in dwindle; its cycle contains only dwindle and scrolling.
Scrolling centers when adjacent windows cannot fit; manual dwindle splits stay
stable. Kitty opacity is configured once; file-manager text stays fully opaque.

Plugin sources are declared in `home/noctalia.nix`, following the official
[plugin-source model](https://docs.noctalia.dev/noctalia/plugins/). Settings → Plugins
shows the official and community Git catalogs, then the `nix-managed` read-only
path source. Later sources take precedence, so the six pinned/patched plugins
continue to win over catalog copies. Home Manager removes its former per-plugin
links during activation. Bump `noctalia-plugins` in `flake.nix` to change the curated
revision; `update` respects that explicit pin. Background Git updates are disabled.
Catalog refreshes and plugin experiments
remain available in Settings; declare wanted changes in Nix to keep them on rebuild.

`Mod+Alt+V` opens Tailscale's manager. Its polling interval is 30 seconds and peer
churn no longer emits notifications. `Mod+S` and the capture submap keep using the
patched Screen Toolkit, including OCR and recording. Umbriel's integration follows
its [animation](https://docs.noctalia.dev/umbriel/animation/) and
[Noctalia](https://docs.noctalia.dev/noctalia/compositor-settings/umbriel/) references;
features are checked against the locked source versions rather than v4 examples.

Visual inspiration: [Noctalia's quiet-by-design unixporn post](https://www.reddit.com/r/unixporn/comments/1mlboeq/)
and [Fami-PL's floating Noctalia rice](https://github.com/Fami-PL/hyprland-dots).
The configuration uses the pinned native Noctalia and Umbriel options.

[SHORTCUTS.md](SHORTCUTS.md) lists daily controls. `Mod+S` opens Screen Toolkit;
`Mod+Shift+S` enters capture shortcuts; `Mod+Ctrl+S` opens settings;
`Mod+Shift+Escape` shows Umbriel's actual live bindings.

The next useful upgrades are encrypted backups of home data, project-specific
`.envrc`/development shells using the existing direnv integration, and CI checks
for configuration/input updates. Measure boot/session performance before changing
drivers or schedulers. Nix recreates software; it does not back up
personal documents, browser profiles or credentials.

## Gaming workflow

Use these Steam launch options:

```text
game-run %command%
game-run --integrated %command%
```

The first uses NVIDIA PRIME offload on this laptop; the second uses the iGPU.
Both invoke GameMode, which gives participating processes nice -10 without
realtime scheduling, CPU pinning/parking or GPU clock overrides. On NixOS they
hold a temporary performance profile, released when the launcher exits.
For a build, use `performance-run cargo build`. Apply the game option to the
actual game command: a launcher that detaches can release its hold too early.
A profile-acquisition failure prevents workload launch. Manual profile changes
remain available, and `powerprofilesctl set balanced` suits ordinary AC use.

The AMD EPP driver retains its `powersave` governor, which permits boosts via
EPP. GameMode does not force a competing governor. Start a fresh login for new
`gamemode` group membership and verify `gamemoded -s` and the GPU used by the game.

Compare repeated game scenes on AC using the same GPU, warmed shader cache and
power profile. Record frame times, 1% lows, temperature and power. Builds cannot
establish FPS gains or replace suspend/resume, displays and controller testing.


## Steam Maintenance

Millennium stays on the flake's existing upstream pin and uses its own nixpkgs
for Steam's FHS runtime compatibility. Material stays pinned to revision
`f91b4e9cbc5436f149e6b293391a9a96ab47fbe9`. Nix owns theme updates; do not
reinstall the managed theme through Millennium's download UI.

The explicit setup helper manages only these links:

```text
~/.steam/steam/ubuntu12_32/libXtst.so.6
~/.steam/steam/ubuntu12_64/libXtst.so.6
~/.steam/steam/millennium/themes/Material-Theme
```

The first two target Millennium's x86/hhx64 bootstrap libraries; the third
points to the packaged theme. It keeps the `Material-Theme` name because its
Matugen script requires it. Theme CSS links to Noctalia's writable `steam.css`;
its colors use Material RGB channel triples and `--theme-color: "Matugen"`.
Appearance preferences remain user-owned.

Steam must stay stopped during setup. Preview and apply do not replace accounts,
games, configuration or userdata, and unmanaged conflicts are refused. Recovery
folders contain `old-0`, `old-1`, `old-2` for the destinations in the order above.
Inspect current paths before restoring them. To opt out, stop Steam and remove
only these links after verifying their targets, then use ordinary Steam.
Steam updates can break runtime hooks even when pinned packages build.


## Plugin Maintenance

Home Manager ships Screen Toolkit, Nix Monitor, Phone Connect, Pomodoro,
Tailscale and Game Launcher from the existing community pin. Local plugin
sources take precedence; Git sources and automatic plugin updates are disabled.
These plugins belong to the NixOS desktop profile. Declared settings take
precedence after activation; prior GUI overrides are backed up and reconciled.

The package applies three maintained patches:

- Screen Toolkit uses private random mode-0700 scratch directories and cleanup
  traps. Umbriel window capture selects one active identifier and uses `grim -T`
  for the isolated client surface. Preview/editor handoff and cursor flags stay
  intact; Niri/Hyprland adapters remain available.
- Nix Monitor validates complete Git hashes, checks exit statuses, shows failed
  checks as errors/stale data, and suppresses update availability until retry
  succeeds. It ticks every ten seconds, checks local revision once per minute,
  and leaves expensive store scanning disabled. The packaged updater refreshes
  inputs, builds and switches through nh, then updates Flatpaks.
- Game Launcher's C helper is compiled during packaging, avoiding runtime
  recompilation inside an immutable plugin directory.

The package checks shell syntax, compiles Luau/C, and runs mocked capture and
monitor tests. These do not perform real captures, uploads or recordings.
Plugins run as trusted unsandboxed user code. Instance directories can remain
for detached recordings/editors until system temporary-file cleanup; SIGKILL
cannot run traps. Recording stop uses path-scoped `pkill -f`. The pinned host
caps captured subprocesses at 60 seconds and supplies no cancellation handle,
so manual monitor cancellation is disabled. External uploads and phone/device
services retain their ordinary native requirements.


## Recorded Graphics Observations

These are historical observations, not new hardware tests. `AMD_DEBUG=nodcc`
fixed pink/blue stripes in tiled windows by disabling radeonsi Delta Color
Compression. It costs memory bandwidth and requires a fresh login. Keep it
available to the greeter as well as the user session.

A separate flicker exposed wallpaper while borders stayed visible, especially
on battery. Earlier tests did not resolve it by removing visual effects,
reverting the kernel/lockfile, adding nodcc, or testing PSR/PSR-SU/Replay/IPS
with `amdgpu.dcdebugmask=0xE10`. VRR was off, rendering/scanout used the same GPU,
and no display underflows were observed. The historical symptom resembled
niri-wm/niri#2030; its frame-completion workaround was removed with Niri.
Disabling direct scanout remained an untested possibility.

Lower refresh rates reduced symptoms without proving a clock-related cause.
Do not restore the old automatic 60/100/165 Hz switching service or remove
visual effects as a purported fix. Keep the `amdgpu_dpm` profile action disabled;
its old policy selected `low` on power saver. NVIDIA runtime suspend already
worked with `finegrained = false`; changing it requires suspend testing.
Shader caches and hardware render policies are retained.
