# Desktop appearance

Noctalia owns the wallpaper palette, bar, dock and shell surfaces. Umbriel owns
layout, blur, borders and animation settings. Home Manager writes their base
configs; Noctalia writes runtime state and rendered palette files itself.

The desktop is styled after macOS. `home/noctalia-settings.nix` sets the
edge-to-edge translucent top menu bar, the floating magnifying dock, the
Spotlight-style launcher and the icon app switcher. `home/umbriel.nix` sets
floating (stacking) windows by default, centered, translucent title bars with
red/yellow/green buttons on the right (button colors are fixed; bar and text
colors follow the palette through `assets/templates/umbriel/title-bar.toml`), vibrant blur, deep soft shadows, the top-left Mission Control hot
corner and 160% laptop scaling. GTK and the shell use Inter.

The dock uses smart auto-hide: it shows on an empty desktop, hides while windows
are open (they keep the full height) and reveals at the bottom edge. The login
screen (`system/greeter.nix`) and lock screen follow macOS: a large clock at the
top, heavily frosted wallpaper, a slim password field, no logo or scheme picker,
and Do Not Disturb while locked. The lock screen layout targets the laptop
panel; other monitors keep Noctalia's default login box. Change wallpaper,
theme mode or power profile in Noctalia.

Kitty and Umbriel include the two palette files configured in `home/noctalia.nix`.
Luciole follows the same palette through `~/.config/luciole/colors.toml`, rendered
from `assets/templates/luciole/colors.toml` (a copy of Noctalia's upstream Luciole
template, which the locked Noctalia predates).
Missing files on the first start use native defaults. Select a wallpaper in
Noctalia to render them; no startup service seeds or rewrites settings. Bundled
wallpapers are available under `~/.local/share/noctalia/wallpaper-samples/`.

GTK and KDE color schemes use Noctalia's built-in templates. Starship uses the
shared static configuration. Editors, browser and Steam
use their ordinary themes. There are no custom theme extensions, browser-profile
rewriters, plugin patches or application theme installers.

GUI overrides in `~/.local/state/noctalia/settings.toml` take precedence over the
base config. Reset an individual setting through Noctalia when you want to return
to the declarative value. Existing overrides and personal wallpapers are not
automatically deleted or reconciled during rebuilds.

Validate using the versions installed by the flake:

```sh
umbriel config validate -c ~/.config/umbriel/config.toml
noctalia config validate ~/.config/noctalia/config.toml
```

## Documentation review (2026-11-03)

Reviewed the current [Umbriel layout](https://docs.noctalia.dev/umbriel/layout/),
[appearance](https://docs.noctalia.dev/umbriel/appearance/) and
[Noctalia configuration](https://docs.noctalia.dev/noctalia/configuration/) docs.
The compositor and shell revisions, along with their matching portals/package
sets, are refreshed in `flake.lock`; the host Nixpkgs input stays unchanged.
Umbriel now tracks upstream through its lock instead of an immovable URL commit,
so `up` can refresh it too.

Dwindle remains the initial layout. Stacking replaces scrolling in the layout
shortcuts on NixOS and native Linux. Title bars respect application decoration
preferences, and stacking supports edge/corner drop zones. Noctalia's upstream
Umbriel palette template supplies matching title-bar colors.

Noctalia Greeter uses greetd with the same Umbriel session. Appearance Auto-Sync
is enabled for the NixOS desktop, with a narrowly authorized Polkit helper for
wallpaper/palette sync (the greeter TOML keeps administrator-controlled defaults).
The greeter applies a softly blurred and tinted wallpaper behind a centered
clock, with a dark fallback before the first sync. Its declarative settings
intentionally leave palette, scheme, wallpaper image path and font unset so
Noctalia's current theme and selected wallpaper remain in charge. After the
first login, open Noctalia **Settings → Security → Noctalia Greeter → Sync Now**
once to transfer the desktop look immediately. Later wallpaper/palette/font
changes automatically synchronize.

The declarative config/runtime-state split and optional palette includes still
match the current docs. Keep GUI overrides in state: resetting a changed setting in the UI
is preferable to introducing another configuration rewrite service.

For native installs, update Umbriel and Noctalia with the distro package manager
before using newly introduced options. Standalone Home Manager manages apps and dotfiles; the distro still supplies
the compositor and shell. Run both validators after native package updates; CI checks the NixOS and
native files against the locked binaries.
