# Desktop Configuration

NixOS plus a shared Home Manager desktop for Linux with Nix. Umbriel,
Noctalia, shell/editor tools and user applications share one configuration.
GNOME remains a NixOS fallback session. The tested platform is `x86_64-linux`;
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

Run as your ordinary user, never root. Default mode builds without activation:

```sh
bash bootstrap.sh --build-only
bash bootstrap.sh --activate
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
bash bootstrap.sh --setup-host
bash bootstrap.sh --setup-host --apply-host
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
| KDE Connect | Native TCP and UDP `1714-1764` receiving rules on all networks |
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
- `Mod+T` opens Kitty; `Mod+Return`
  toggles floating; `Mod+S` captures a region. `Ctrl+Shift+3` captures the active
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
- KDE Connect remains available on all networks. LocalSend is removed. Other
  firewall rules remain enabled; Docker and WinBoat retain their accepted risks.
- Home Manager owns GNOME applications, KDE Connect, GVfs, Wireshark/recorder
  GUIs, GameMode, user units, Flatpak CLI and user installations. Tablet/NVIDIA
  utilities remain laptop-gated. Native configuration retains boot/storage,
  drivers, accounts, system services, PAM, firewall, device rules, privileged
  capture/GameMode helpers, and display-manager/portal registration. GNOME's
  native session/keyring infrastructure stays intact; greeter assets and the
  host graphics workaround are not moved into one user's login environment.
- PlatformIO uses one Nix Core across editors and shells. Framework/toolchain
  downloads remain project-specific; notebook environments remain purpose-specific.
- Noctalia plugin code is pinned and patched; see `nixos/pkgs/noctalia-plugins.md`.
  Saved disabled-widget layouts and graphics workarounds are intentionally kept.

The laptop-only display modes, mirroring shortcut, storage alias and NVIDIA
Blender wrapper are excluded from standalone Linux. `isLaptop` in these modules
means this configured laptop, not an arbitrary laptop capability claim.

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
| Kitty | Generated state-file include; running instances receive reload signal |
| VSCodium | Declarative NoctaliaTheme extension reading writable state JSON; no static color overrides |
| Zen | Pinned CSS and profile-import hook; original CSS/user.js backed up once, restart browser |
| Steam | Approved pinned Millennium + Material integration; explicit initial setup below |
| Neovim | Base16 palette; initial load and per-instance refresh on FocusGained |
| Btop / Bat | Selected generated themes; Btop reload and Bat cache rebuild hooks |
| Fzf / Lazygit / Yazi | Generated shell palette, launch-time colors overlay and selected flavor |
| Starship | Builtin palette hook; application config stays writable |

Refresh with `noctalia msg templates-apply`. VSCodium receives an initial palette
generated by Noctalia only when its state JSON is absent, so first launch also
works from GNOME. Reload its window if a running editor misses a palette update.
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

The first command previews links; the second refuses unmanaged conflicting paths.
Start the configured Steam wrapper, select Material and Color = Matugen, then
restart Steam. Rerun setup after Millennium updates or if Steam removes the
bootstrap links. See `nixos/pkgs/steam.md` for removal and maintenance details.

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
bash tests/bootstrap.sh
bash tests/host-setup.sh
nix eval --impure --json --expr '(import ./tests/portability.nix { flake = builtins.getFlake ("path:" + toString ./nixos); }).checks'
nix build --no-link path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel
nix build --no-link path:./nixos#homeConfigurations.oad.activationPackage
```

The default names in those build commands follow the shipped profile; change
them when changing its names. Bootstrap and `up` derive names automatically.
Use `path:` while modules are untracked. The portability tests instantiate a
different user with custom/quoted paths, not only simulated bootstrap responses.
Reconciliation tests use Python with the pinned `tomlkit` dependency.
Native-setup tests mock package managers and confirmations; actual Fedora/Debian
transactions, SELinux behavior and graphical logins still need VM/hardware tests.

This cleanup is built/tested but not activated automatically. For the current
deployment record, backups, accepted risks and hardware testing limits, see
`nixos/OPTIMIZATION.md`. Recorded graphics investigations are in
`nixos/GRAPHICS.md`. Keep both state-version values unchanged.
