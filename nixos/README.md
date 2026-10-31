# Configuration notes

`flake.nix` imports this host and `home/default.nix` directly. This is a personal
system configuration: there are no development shells, custom test framework or
language-toolchain catalogue.

| Location | Purpose |
| --- | --- |
| `profile.nix` | Account, host and checkout location |
| `configuration.nix` | Host entry point and optional application choices |
| `hardware-configuration.nix` | Generated locally, ignored by Git |
| `hardware.nix` | Laptop GPU, peripherals and storage |
| `system/` | Boot, desktop, networking, backups and optional bundles |
| `system/applications/` | Everyday applications and desktop services |
| `home/` | Shared dotfiles and small editor preferences |
| `pkgs/` | Desktop helpers and necessary package overrides |
| `native/` | Debian/Fedora application installation |

The direct structure takes inspiration from
[Misterio77's minimal starter](https://github.com/Misterio77/nix-starter-configs/tree/main/minimal).
Neovim follows the [LazyVim starter](https://github.com/LazyVim/starter), with Nix
support and the existing desktop palette instead of a preinstalled language suite.

## Applying changes

Use `path:` flake references so the ignored local hardware file participates.
The setup script copies it from `/etc/nixos`, backing up a changed predecessor:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos-setup.sh
```

Do not change `system.stateVersion` or `home.stateVersion` as part of an upgrade.
On another machine, adapt `profile.nix`, review `hardware.nix` and provide that
machine's generated hardware configuration.

For an existing Debian/Fedora installation with Nix and native applications:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate --backup-extension bak
```

Standalone `oad` and `oad-desktop` outputs retain the same full dotfile scope.
They install no applications. Their names follow `profile.nix`.

## Editors and project tools

NixOS installs regular VSCodium and Neovim with only Nix tooling. Their starter
settings are copied once into writable user files. Edit LazyVim normally in
`~/.config/nvim/init.lua` and `~/.config/nvim/lua/`; use `:Lazy` and `:LazyExtras`
to manage plugins. Codium owns its settings, keybindings, profiles and extensions;
change them through its UI or `~/.config/VSCodium/User/settings.json`.

Rebuilds preserve your edits and deletions, including removed plugins/extensions.
The first activation converts the old Nix-store links and backs up their content
under `~/.local/state/editor-defaults/backups/`. Close both editors before
applying, then reopen them. One-time initialization markers live alongside those
backups; subsequent activations do not reapply the starter.

LazyVim downloads its plugins on first use. The initial bootstrap shows progress
and falls back to plain Neovim if its download fails or exceeds 30 seconds; restart
to retry. Plugin Git operations also have a 30-second timeout. Completion uses Lua,
so it needs no downloaded native library or Rust compiler. Mason, Tree-sitter
compilation and Neovim's language providers are disabled in the editable starter.
Neither editor gets a Python virtual environment, Jupyter kernel, language extras, compiler suite or debugger
from this configuration.

Activation repairs the exact previous starter with these startup fixes, backing
it up first. Edited files and deleted files remain untouched.

Use each project's own environment for language packages. `editor-setup` on other
distributions only syncs editor plugins and the small extension list. Old manually
created `editor-python` environments and user-installed extensions are not erased;
remove them yourself if you no longer use them. Managed notebook configuration
and kernels disappear when Home Manager applies the new generation.

## Desktop and maintenance

Home Manager writes preferences. NixOS or the native distribution owns desktop
services, portals and applications. `desktop-apply` runs at graphical login;
activation does not need a running compositor or network downloads.

Optional bundles own their packages, services and Flatpaks. Disabling one does
not erase application data. Existing Flatpaks are retained, and fonts remain
available through the read-only `/usr/share/fonts` mount.

Backups use `/mnt/storage/backup`; see [BACKUPS.md](BACKUPS.md) for recovery and
password storage. Docker is socket-activated when the containers bundle is enabled.
The NVIDIA/kernel pair, state versions and storage policy are unchanged.

GitHub Actions performs ordinary Nix evaluation against disposable hardware and
both standalone home outputs, then validates the generated TOML with the pinned
Umbriel executable. It never activates or deploys that hardware.

Umbriel actions use whitespace-separated arguments: `spawn kitty`,
`workspace-switch 2`, and `workspace-set-layout toggle dwindle scrolling`.
Noctalia plugin IDs such as `alexander/screen-toolkit:service` keep their colons.
The Umbriel input is pinned to the revision tested with this syntax. After
rebuilding, log out and back in to run the matching compositor version.
For a real machine, build the system before switching and test login/suspend
when changing graphics or display-manager settings.

If Flatpak reports missing refs despite the Flathub remote being
`https://dl.flathub.org/repo/`, repair the local installations and retry:

```sh
flatpak repair --user
sudo flatpak repair --system
flatpak update
```

This repairs repository objects; it does not delete application data. Persistent
missing-ref warnings require checking Flathub availability and remote metadata;
changing an already correct remote URL is not a fix.

## Everyday desktop

The bar keeps the launcher, numbered workspaces, clock, media and essential status.
Clipboard, capture, phone, VPN, Pomodoro and Nix updates remain available through
shortcuts and panels. The bottom bar stays visible; the quieter right dock reveals
on hover. English/Arabic input status remains visible.

Workspaces are dynamic and numbered. `Mod+1…9` selects a workspace, and
`Mod+Ctrl+1…9` moves a column there. Applications open on the current workspace;
there are no per-application workspace assignments. `Mod+D` retains the
dwindle/scrolling toggle.

- `Mod+grave`: summon a terminal scratchpad, launching Kitty when empty.
- `Mod+Ctrl+Return`: summon a calculator scratchpad.
- `Mod+Ctrl+P`: start presentation mode (DND and idle inhibition).
- `Mod+Ctrl+Shift+P`: end presentation mode (notifications and idle actions resume).
- `Mod+Alt+U`: open Nix Monitor. Other plugin shortcuts are unchanged.

The generic scratchpad shortcuts now target `stash`. Presentation controls set
explicit on/off states; end mode resumes idle actions even if caffeine was enabled
manually before presenting.

On this laptop, Noctalia's existing power hooks select balanced on AC and
power-saver on battery. Idle lock/screen-off are 10/15 minutes on AC and 5/6 minutes
on battery; battery suspend locks first after 20 minutes. Presentation mode and
normal Wayland idle inhibitors prevent these idle actions. Manual power-profile
choices last until the next power-source change, shell startup or `desktop-apply`.

Closing the lid suspends when undocked; with an external display, logind leaves the
docked session running. HDMI uses the connected display's preferred mode at 100%
scaling to the right of the 160% laptop panel. Native output hotplug restores
workspaces. `Mod+Shift+M` retains explicit projector mirroring. Audio uses
WirePlumber's native device/volume restoration; choose the preferred output and
microphone once in Control Center when first connecting a device.

Apply and log out/back in for workspace, scratchpad and lid-policy changes.
Test physical hotplug and suspend/resume on the laptop; remote evaluation cannot
exercise its displays, headset or GPU wake behaviour.

## XP-Pen Deco mini7

The laptop uses its existing OpenTabletDriver service in Artist Mode, which
delivers pen pressure and native stylus buttons to Wayland applications. The seed
maps to the laptop panel at 1600×1000 logical pixels, derived from the shared 160%
display scale. Its centered active area matches the panel's 16:10 aspect ratio;
pressure and tilt remain enabled, with no additional smoothing filters.

`Mod+Ctrl+Alt+T` opens the driver settings. The express keys provide zoom,
navigation, paste/copy and undo/redo; see [SHORTCUTS.md](SHORTCUTS.md). Xournal++
already enables pressure sensitivity by default. Activation assigns Eraser and
Hand to missing/"No action" stylus-button mappings, preserving other tool choices
and backing up changed settings. Close Xournal++ before rebuilding so this can
apply; it skips the running application. Hold a pen button while touching/moving
on the page to use its temporary tool; releasing restores the previous tool.
These mappings are separate from the mouse-button and physical eraser settings.

Rebuilds repair the recognizable old 1707×1067 mapping and previous F6 express key,
backing up the original settings before changing them. Custom display/tablet
areas, output modes, pressure settings, filters and express-key bindings survive.
Use the driver GUI to select another screen or calibrate a personal active area.
OpenTabletDriver owns the coordinate mapping; leave Umbriel's tablet mapping at
its defaults to avoid applying that transform twice.

OpenTabletDriver 0.6.7 snapshots the output layout at startup. After connecting,
disconnecting or rearranging displays, lift the pen and restart its user service:

```sh
systemctl --user restart opentabletdriver.service
```

Restart the service after applying these defaults, or log out/in. Check all four
screen corners, varying stroke pressure and both pen buttons in Xournal++; these
require the physical tablet.
