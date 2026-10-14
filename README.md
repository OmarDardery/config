# Desktop Configuration

NixOS plus a shared Home Manager desktop for Linux with Nix. Umbriel,
Noctalia, shell/editor tools and user applications share one configuration.
GNOME remains a fallback session. The tested platform is `x86_64-linux`;
this is not a Nix-free or macOS deployment.

## Deployment Profile

`nixos/profile.nix` is the single source for username, home directory, checkout
path, host/profile names, platform and Git identity. Defaults remain `oad`,
`/home/oad`, `~/configs/nixos`, and host `nixos`.

For another Linux account, set these values explicitly before bootstrapping.
Use `null` for `gitName`/`gitEmail` if Git identity should remain unmanaged.
The shared Home Manager modules no longer hardcode the author's account.
Rebuild aliases and both editors' nixd queries follow the selected profile.
`cnf` opens the backend's configuration file, not an uneditable directory.

`nixos/package-policy.nix` supplies the user/dev-shell package policy, including
the explicit EOL Electron exception needed by retained WinBoat. Integrated Home
Manager has its own package set; the host does not permit that insecure runtime.
System hardware is
separate in `hardware.nix` and `hardware-configuration.nix`; changing the profile
does not turn this laptop's NixOS configuration into a generic installer.

## Bootstrap

### Debian 13 on this laptop

From a Debian 13 installation with the `oad` account and working `sudo`, run:

```sh
curl -fsSLo "$HOME/debian-setup.sh" https://codeberg.org/oadardery/configs/raw/branch/main/debian-setup.sh && bash "$HOME/debian-setup.sh"
```

The script installs SDDM with Umbriel and GNOME sessions, native graphics/audio,
Bluetooth, keyring, Polkit, Docker/Compose, Flatpak, and device services. It
installs multi-user Nix, configures the Noctalia cache, clones this repository
to `~/configs`, activates the same-laptop Home Manager profile, links its Mesa
stack for Nix applications, installs tablet
and PlatformIO udev rules, and registers Umbriel with SDDM. It is safe to rerun:
an existing checkout is used without pulling or resetting it, and package and
service operations are idempotent. Reboot after completion, select Umbriel in
SDDM, and sign in again so new group membership and device rules take effect.
It configures `en_US.UTF-8` and the `Africa/Cairo` time zone to match the
current NixOS host.

The installer needs network access, sudo, and Debian APT sources with
`non-free-firmware` for AMD firmware. `contrib non-free non-free-firmware` are
needed for the Debian NVIDIA driver. If `nvidia-driver` is unavailable, the
script completes on the AMD graphics path and reports that GPU offload remains
unavailable; enable those Debian components and rerun. The Docker group grants
root-equivalent access, and the Wireshark group grants packet capture. The
script leaves an existing `~/configs` checkout untouched, so update it before
rerunning if you want newer configuration.

Nix applications using the NVIDIA GPU need a Home Manager driver library pin
that exactly matches the Debian driver. The installer brings up the desktop on
AMD and installs Debian's NVIDIA driver when available; the matching Nix library
pin remains a post-install task before using `nvidia-offload` with Nix apps.

This installer is specific to Debian 13 on the configured `oad` laptop. The
generic bootstrap below remains available for other supported Linux hosts.

Run as your ordinary user, never root. Default mode builds without activation:

```sh
bash nixos/bootstrap.sh --build-only
bash nixos/bootstrap.sh --activate
```

The script detects NixOS versus another Linux distribution and reads the
default output names from the deployment profile. `--repo-dir`, `--profile`
and `--host` can select an existing checkout or explicitly declared output.
Selectors do not infer or rewrite deployment identity.

- Existing checkouts are never pulled, reset or staged.
- Lockfiles, hardware files and `/etc/nixos` are not rewritten.
- Architecture and identity are checked before building; NixOS also checks
  mounted root/boot UUIDs and filesystem types.
- Activation uses the exact built closure. NixOS also requests confirmation.
- A temporary garbage-collection root retains the build through confirmation and
  activation. It is removed on exit, including failure or cancellation; build-only
  results are not retained by bootstrap after it exits.
- Standalone activation runs without sudo. For existing unmanaged files, opt
  into backups with `--activate --backup-extension bak`; inspect/merge backups
  rather than blindly overwriting user configuration.

Use `--install-nix` for official installation instructions if Nix is absent;
bootstrap does not execute a downloaded installer. Bootstrap enables Nix
features for its own calls, and standalone Home Manager configures them for
later rebuilds. Nix cache trust still belongs to the native daemon administrator.
Publish or transfer the complete checkout before using it on another machine;
local uncommitted modules do not exist in an older remote checkout.

### Fedora And Debian

The shared Home Manager profile supplies the applications and user services on
mutable Fedora and Debian. Native prerequisites are a separate, opt-in action:

```sh
bash nixos/bootstrap.sh --setup-host
bash nixos/bootstrap.sh --setup-host --apply-host
```

The first command is a read-only preview and works before Nix is installed. The
second installs only missing baseline Polkit/native-agent, PAM/user-bus, keyring,
UDisks2/GVfs, Bluetooth and power-service packages after an exact `yes` terminal
confirmation. DNF/APT still shows its own transaction confirmation. Repository
metadata must already provide the packages; no repository is added or updated
by preflight. Package scripts may configure PAM/services or start services.

Only exact mutable Fedora (standard, Workstation or Server) and Debian IDs are
accepted. OSTree/Atomic editions and derivatives are refused rather than treated
as interchangeable. Managed Umbriel sessions require installed **and running**
systemd >=254: Debian 13 is suitable; stock Debian 12 requires a manual upgrade.
This is prerequisite setup, not a desktop-readiness certification.

Host setup never clones/builds/activates a profile and cannot be combined with
deployment flags. It does not switch audio/network stacks, enable services,
change drivers or SELinux, configure firewall/groups/Docker, edit PAM itself,
or register a display-manager session. Review the printed remaining checks.
Then install Nix using official instructions, edit `profile.nix` for your account,
and run the normal build/activation commands. User Flatpak installation does not
require a native Flatpak package; Home Manager supplies its CLI.

## Native Linux Requirements

On NixOS, logind ignores the power key and Umbriel handles it: a short press
locks with Noctalia, whose secure login box shows logout, suspend, reboot and
shutdown controls. The binding also works while locked or shortcuts are inhibited.
`Mod+Shift+Q` still opens the ordinary session menu without locking.
Other distributions need equivalent native logind configuration; Home Manager
does not change it. The NixOS setting also suppresses logind's power-key action
outside Umbriel; other sessions need their own handler. Firmware-enforced shutdown
from holding the button cannot be disabled by this configuration. Saved Noctalia
GUI settings can override the session-action list or hide lock-screen buttons.

Home Manager configures user software, not native kernel drivers, accounts,
system daemons or privileged permissions. The standalone profile supplies
generic-Linux graphics integration, fonts, Bash/Zsh initialization, compositor
user units, portals and D-Bus registrations.

| Feature | Native Host Requirement |
| --- | --- |
| Desktop | Working systemd user manager, Wayland session/seat, Polkit and secret-service/PAM integration |
| Graphics | Native kernel driver; run the generated generic-Linux GPU setup helper as instructed |
| Proprietary NVIDIA | Enable `targets.genericLinux.gpu.nvidia` with the exact native version and runfile hash; update it with the native driver |
| Audio/Bluetooth | PipeWire/session services and BlueZ for Bluetooth devices |
| WinBoat | Compatible rootful Docker, socket access and usable KVM/TUN devices |
| KDE Connect | Native TCP and UDP `1714-1764` receiving rules on the Tailscale interface only |
| Embedded tools | PlatformIO udev rules and serial-device permissions |
| Capture/tablets/controllers | Native dumpcap/KMS privileges and required device/driver services |
| Flatpaks | Usable unprivileged user namespaces, fonts, portals and matching graphics runtimes; CLI/apps/remotes/updates belong to HM |
| GameMode | NixOS provides helper capabilities/polkit; standalone runs unprivileged until native authorization for the exact Nix helper paths is configured |

Do not simultaneously enable nixGL and the generic-Linux GPU integration.
Home Manager's Bash/Zsh configuration does not change the account's native
login shell. Start a fresh login that loads the managed environment.

The standalone profile uses a consistent **Nix user portal stack**, including
its frontend and GTK/GNOME/Umbriel backends plus the Secret portal descriptor.
The existing native PAM-unlocked keyring daemon supplies Secret; no second daemon
is installed or started by the portal metadata. It can override native portal
services for this user, not just supply extra configuration. Backend selection
is desktop-specific, with no common Umbriel override. For native KDE or another
desktop, add the appropriate backend to `xdg.portal.extraPortals` and configure
that desktop's selection; do not assume a native backend is automatically
discovered by the Nix frontend. Foreign-distro session behavior needs testing.

Native display managers need administrator-level session registration. From a
login TTY, use `start-umbriel`; managed Umbriel sessions need
systemd 254 or newer. Avoid concurrent graphical sessions under one account
when assuming isolated systemd/D-Bus environments.

On standalone hosts, Umbriel starts the native polkit-gnome agent, not Noctalia's
NixOS-dependent built-in agent. Fedora needs `polkit-gnome`; Debian needs
`policykit-1-gnome` (included in host setup). GNOME keeps its own agent. If carrying
old Noctalia GUI settings between hosts, review/reset `shell.polkit_agent` with
`noctalia-reconcile` so a saved value does not re-enable the incompatible agent.

## Applications And Desktop

- NixOS SDDM offers Umbriel (default) and GNOME (fallback). Niri's package,
  configuration, portal/session registrations and theme generation are removed.
- Noctalia starts from Umbriel, not as a global GNOME service. Umbriel uses
  English/Arabic input, the shared cursor, scrolling/tabbed layouts and springs.
- Umbriel prefers border-only server decorations. VSCodium hides its window
  controls through its custom titlebar setting; Zen hides its window controls
  through profile CSS applied alongside the Noctalia palette. This preference
  also applies in the GNOME fallback. Close windows with `Mod+Q` in Umbriel or
  the application's normal keyboard command.
- `Mod+E` opens Thunar, the default file manager. `Mod+T` opens Kitty; `Mod+Return`
  toggles floating; `F6` captures a region. `Ctrl+Shift+3` captures the active
  window's isolated surface to the clipboard. Native screenshots still follow
  Noctalia's save/clipboard preferences. `Mod+Ctrl+F` maximizes instead of expanding
  only into free space; `Mod+Ctrl+C` centers the active column, not all visible ones.
  Non-conflicting Umbriel built-in shortcuts remain available.
- In Umbriel, `Mod+D` cycles the current workspace's layout through scrolling
  (strip tiling), dwindle (splits), and master. `Mod+Up/Down` switches workspaces;
  the former workspace bindings `Mod+WheelUp/Down` now navigate windows/tabs,
  as do `Mod+K/J`. `Mod+Ctrl+WheelUp/Down` still moves a column between workspaces.
- User Flatpaks declare OrcaSlicer and ProtonPlus with weekly updates. Unmanaged
  apps/runtimes are preserved. NixOS also prepares the configured NVIDIA GL
  extension; check Flathub availability before future driver upgrades.
- KDE Connect accepts incoming connections over Tailscale only. Tailscale is
  enabled on NixOS; run `tailscale up` after rebuilding to authenticate, and add
  the peer's Tailscale IP in KDE Connect. LocalSend is removed. Other
  firewall rules remain enabled; Docker and WinBoat retain their accepted risks.
- Home Manager owns selected desktop applications, KDE Connect, GVfs, Wireshark/recorder
  GUIs, GameMode, user units, Flatpak CLI and user installations. Tablet/NVIDIA
  utilities remain laptop-gated. Native configuration retains boot/storage,
  drivers, accounts, system services, PAM, firewall, device rules, privileged
  capture/GameMode helpers, and display-manager/portal registration. GNOME's
  native session/keyring infrastructure stays intact; greeter assets and the
  host graphics workaround are not moved into one user's login environment.
- Rust's pinned compiler, Cargo, Clippy, Rustfmt and native linker are available to GUI editors
  and the default/general development shells. For project-selected toolchains,
  use `nix develop path:./nixos#rustup` and explicitly install/select the required
  toolchain with Rustup; no toolchain download runs during activation.
- On NixOS, the configured user belongs to `gamemode`; the host exports the
  upstream GameMode policy actions and group authorization rules. Log out and
  back in after activation to pick up the new group. GPU tuning settings remain
  unchanged; standalone hosts still need native privilege setup.
- PlatformIO uses one Nix Core across editors and shells. Framework/toolchain
  downloads remain project-specific; notebook environments remain purpose-specific.
- Neovim's inactive DAP/test plugin packages are omitted; add them with the
  corresponding LazyVim extras when enabling those workflows.
- Neovim uses LazyVim's native Copilot integration on Neovim 0.12. Run
  `:LspCopilotSignIn` once if the language server has not picked up your GitHub
  login. Inline suggestions use LazyVim's normal `<Tab>` acceptance and
  `Alt-]`/`Alt-[` to cycle. Copilot stays out of the `blink.cmp` source list.
  `<leader>ac` or `:Codex` opens the existing Codex CLI in a reusable right
  terminal at the detected project root, using the account's Codex login.
  Project detection also recognizes PlatformIO, Nix, Python, Go, Rust and
  JavaScript manifests outside Git checkouts.
- Noctalia plugin code is pinned and patched; see [plugin maintenance](#plugin-maintenance).
  Saved disabled-widget layouts and graphics workarounds are intentionally kept.

GNOME's default app bundle originally brought Maps, Connections, Web/Epiphany,
Calendar, Contacts, Weather and other optional applications into the fallback
session. It was later copied into Home Manager. These applications are not
requirements of Umbriel, Noctalia or the GNOME session; the bundle is now replaced
by an explicit selection. Thunar handles files, Papers handles PDFs, Calculator
provides a desktop calculator, Disks handles devices, Settings supports the
GNOME fallback, and Seahorse provides credential management/SSH askpass.
Papers' optional Nautilus extension is disabled so it does not retain the removed
file manager as a dependency. GVfs, Tumbler and Xfconf support mounts/trash,
thumbnails and Thunar preferences.
Existing Zen, Kitty, imv, mpv and development editors cover the duplicated
browser, terminal, image/video and text-editor roles. Obsidian is removed.
Removing packages does not delete their user data. GNOME's native settings,
keyring, portal and session dependencies remain available.

The standalone profile now targets the same laptop: it includes the display
modes, mirroring shortcut, storage alias, tablet service and NVIDIA Blender
wrapper. `isLaptop` in these modules means this configured laptop, not an
arbitrary laptop capability claim. On Debian, the NVIDIA settings application
comes from APT so its version matches the native driver.

## Noctalia State

Noctalia is the palette source. It generates colors from the selected wallpaper
and mode; application modules select those palettes rather than hardcoding colors.
Visual settings remain in `nixos/dotfiles/noctalia/config.toml`; pinned template
inputs and writable destinations are declared in `nixos/home/noctalia.nix`.

| Consumer | Integration / Refresh |
| --- | --- |
| Umbriel | Optional state-file include; borders, tabs, overview and shadows reload automatically |
| GTK 3/4 | Generated CSS, declarative imports, adw-gtk3 and synchronized appearance preference |
| Qt/KDE | KDE platform plugin, Breeze style and generated KColorScheme; restart apps if needed |
| Kitty | Built-in template writes writable `themes/noctalia.conf`; running instances receive reload signal |
| VSCodium | Declarative NoctaliaTheme extension reading writable state JSON; no static color overrides |
| Zen | Pinned CSS and profile-import hook; original CSS/user.js backed up once, restart browser |
| Steam | Approved pinned Millennium + Material integration; explicit initial setup below |
| Neovim | Base16 palette; initial load and per-instance refresh on FocusGained |
| Btop / Bat | Selected generated themes; Btop reload and Bat cache rebuild hooks |
| Fzf / Lazygit / Yazi | Generated shell palette, launch-time colors overlay and selected flavor |
| Starship | Builtin palette hook; application config stays writable |

Refresh with `noctalia msg templates-apply`. VSCodium receives an initial palette
generated by Noctalia only when its state JSON is absent, so first launch also
works from GNOME. Bat also receives a missing theme before Home Manager builds
its cache; an existing generated or edited theme is preserved. Reload its window if a running editor misses a palette update.
Fzf takes new colors in newly initialized shells. Zen must have been launched
once to create a profile; custom profile locations need explicit integration.

Steam is a third-party client modification, explicitly approved for this setup.
Steam, steam-run, Millennium and its theme helper are installed by the shared
Home Manager profile; NixOS retains only native gaming/device/audio integration.
After activation, render templates and exit Steam completely, then run:

```sh
noctalia-steam-setup
noctalia-steam-setup --apply
```

The first command previews links; the second refuses unmanaged conflicting paths
and stages all replacements before installing them. Installation failures restore
previous links. If rollback fails or another writer intervenes, the helper reports
a private `.noctalia-steam-setup-*` directory containing recovery links; inspect
current paths before restoring those originals.
Start the configured Steam wrapper, select Material and Color = Matugen, then
restart Steam. Rerun setup after Millennium updates or if Steam removes the
bootstrap links. See [Steam maintenance](#steam-maintenance) for removal details.

"System colors" means supported user-session toolkits and applications, not a
forced recoloring of web content, every Electron app, or root/login-screen UI.
Pixie remains the independent greeter. Flatpaks can require sandbox theme access;
host CSS is not automatically available in every sandbox. App-specific theme
extensions and custom browser CSS may override generated colors.

GUI settings still override declarative settings. The previous overrides were
backed up/reconciled; future GUI changes are not silently discarded on activation.
The opt-in helper defaults to previewing only equal overrides:

```sh
noctalia-reconcile
noctalia-reconcile --reset plugins.enabled --reset bar.default.start
noctalia-reconcile --apply --reset plugins.enabled --reset bar.default.start
noctalia msg config-reload
```

It preserves unknown/different values and `config_version`, creates a private
exact-byte backup, checks for intervening changes and atomically replaces state.
Avoid editing the GUI at the same time: the final check is not a filesystem
compare-and-swap lock. Do not delete the whole settings file.

For this palette migration, inspect any saved template overrides before applying:

```sh
noctalia-reconcile --reset theme.templates.builtin_ids --reset theme.templates.community_ids --reset theme.templates.user.niri
```

Add `--apply` only after reviewing the preview, then reload config and templates.
This removes obsolete Niri overrides and lets the declarative template selections
take effect without discarding unrelated GUI preferences.

## Verification And Deployment

```sh
nix flake check path:./nixos
nix build --dry-run path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel
nix build --no-link path:./nixos#homeConfigurations.oad.activationPackage
nix build --no-link path:./nixos#nixosConfigurations.nixos.config.home-manager.users.oad.home.activationPackage
nix build --no-link path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel
```

The default names in those build commands follow the shipped profile; change
them when changing its names. Bootstrap and `up` derive names automatically.
Use `path:` while modules are untracked. The portability tests instantiate a
different user with custom/quoted paths, not only simulated bootstrap responses.
The flake checks supply pinned Python/tomlkit, generated fixtures, and renderer
binaries automatically. They cover portability, reconciliation, state migrations,
updater confirmations, Steam rollback, Bat first-run behavior, offline Rust
compilation/lint/format checks, GameMode authorization, bootstrap/host setup, Kitty migrations and dark/light
rendering of all user templates plus the pinned built-in Kitty template. Template
sources are checked against the generated configuration's closure. Kitty checks
run the pinned Home Manager collision, migration, cleanup and linking stages in
isolated homes, including custom/quoted paths, backup mode and dry runs. They do
not install a real profile or reload services.

Canonical bootstrap scripts and tests live inside `nixos/` so the flake can
include them without additional inputs. There are no root forwarding copies.
Native-setup tests mock package managers and confirmations; actual Fedora/Debian
transactions, SELinux behavior and graphical logins still need VM/hardware tests.

Builds and checks do not activate the system. Keep both state-version values
unchanged. Hardware testing limits and recorded graphics observations are below.

Nix Monitor runs the packaged `nixos-update` command using `path:` flake
references, so new untracked modules are included consistently. It updates all inputs,
previews builds/downloads, and switches only after you type `yes`. Refusal or
EOF leaves the updated lockfile for inspection; command failures stop the flow.
This verification does not run the updater against the real checkout.

Individual state tests remain available through `nixos/tests/desktop-migrations.py`
and `nixos/tests/reconcile-noctalia.py` with Python plus `tomlkit`. The flake check is
the complete verification entrypoint; no manually generated fixture or
`/tmp/opencode` directory is needed.

Kitty preserves edited settings and creates `kitty.backup-*` before replacing a
legacy directory symlink. Failed installation restores the original link and
cleans the transaction directory. If rollback itself fails, the error identifies
`.kitty.migration-*/original-link`, which is retained for manual recovery. Move
that link back only after inspecting any file occupying the Kitty path; the
backup directory retains the original configuration. Existing extra files are
preserved as writable local files; unused images/themes are no longer shipped.
Only the obsolete Noctalia palette include is changed; later settings are retained.

State replacements reject symlinks and special files, retain exact mode-0600
backups, flush writes and detect changes to both contents and file identity.
Noctalia records `.kitty-template-v1` only after successful migration, preserving
later GUI choices. Tablet updates preserve unrelated profiles/settings and the
requested Ctrl+V/F6 bindings. Live rebuilds remain supported without stopping
applications. Detection is best effort: a GUI write after the final identity
check can still race replacement. Avoid editing those settings during activation
and retry when an intervening change is reported.

## Performance And Gaming

The host uses `pkgs.linuxPackages_latest` with the kernel's default CPU scheduler
and native I/O defaults. SCX is disabled, and no custom scheduler or kernel cache
is configured. The boot menu waits two seconds and retains ten generations.

clangd and Rust Analyzer use four background workers/jobs. Explicit terminal
builds and games are not globally limited. Desktop search keeps its standard
exclusions and skips generated `node_modules`, `target`, `build` and `dist` trees.

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
EPP. GameMode does not force a competing governor. Standalone Home Manager's
`game-run` assumes neither power-profiles-daemon nor NVIDIA hardware; its native
GameMode authorization requirements still apply. Start a fresh login for new
`gamemode` group membership and verify `gamemoded -s` and the GPU used by the game.

Compare repeated game scenes on AC using the same GPU, warmed shader cache and
power profile. Record frame times, 1% lows, temperature and power. Builds cannot
establish FPS gains or replace suspend/resume, displays and controller testing.

## Configuration Layout And Resource Policy

- `nixos/configuration.nix` owns boot, networking/Tailscale, accounts, native
  privileges, system services and Nix settings. `nixos/desktop.nix` groups SDDM,
  the GNOME fallback and Umbriel session/portal registration.
- `nixos/hardware.nix` retains laptop drivers/devices and storage; the generated
  hardware file remains separate. Host gaming privileges remain in `gaming.nix`.
- Home modules group applications/3D tools, gaming/Steam, desktop/Kitty, Nix
  tools/deployment aliases, shell, development, Noctalia, Umbriel and Flatpak.
  `home/linux.nix` supplies only the standalone backend's native integration.
- Shared package and state helpers remain separate when used by modules/tests.
  Multiple consumers of a store path do not require duplicate downloads.
- Nix uses two parallel builds and four cores per build, weekly garbage
  collection of generations older than 30 days, and automatic store optimisation.
  Zram provides compressed RAM swap on this laptop.
- Journals are bounded to 1 GiB persistent/256 MiB runtime with one-month
  retention. Docker retains journald and BuildKit's 15 GB cache policy.
- `nix-ld` and the Python development shell share native runtime libraries.
  `nix develop path:./nixos#python` provides a shell-scoped library path for
  uv/pip wheels, including OpenCV. There is no global `LD_LIBRARY_PATH`; use
  only one OpenCV wheel variant, and prefer headless when GUI support is unused.
- WinBoat's user-only EOL Electron exception and Docker group access remain
  accepted choices. The privileged KMS helper stays restricted to `recording`.

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
Tailscale and Nix Monitor are enabled only on NixOS. GUI overrides still take
precedence over declarative choices; use selective reconciliation when needed.

The package applies three maintained patches:

- Screen Toolkit uses private random mode-0700 scratch directories and cleanup
  traps. Umbriel window capture selects one active identifier and uses `grim -T`
  for the isolated client surface. Preview/editor handoff and cursor flags stay
  intact; Niri/Hyprland adapters remain available.
- Nix Monitor validates complete Git hashes, checks exit statuses, shows failed
  checks as errors/stale data, and suppresses update availability until retry
  succeeds. It ticks every ten seconds, checks local revision once per minute,
  and leaves expensive store scanning disabled. The packaged updater previews
  all-input updates and requires `yes` before switching.
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
Noctalia's backdrop blur, shader caches and existing render settings are retained.

## Previous Deployment And Backups

Earlier changes migrated OrcaSlicer/ProtonPlus to user Flatpaks without deleting
application data. These recorded backup locations remain useful:

```text
~/.local/state/noctalia/settings.toml.backup-1790974580636812518-qfo8swpm
~/.local/state/configs-backups/flatpak-migration-20261002T203459Z-ebFewD/flatpak-orcaslicer-protonplus-settings.tar.gz
```

Earlier startup cleanup left SolveX and Hermes installed but stopped. Start them
when needed with `docker compose -f /mnt/storage/Coding/solvex/docker-compose.yml up -d`
and `systemctl --user start hermes-gateway.service`.

Earlier native activation temporarily left loaded NVIDIA 595.91.07 and configured
userspace 610.57.04 mismatched until reboot. This cleanup keeps the 610.57.04 pin;
building does not unload drivers, change live GUI state or reboot. Graphical
Fedora/Debian sessions, native device integration, printer operation, real Proton
downloads and hardware suspend/offload still need their own testing. Umbriel is
pre-release software; the manual Molten registration instructions remain in its
editor module.
