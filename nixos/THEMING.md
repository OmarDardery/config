# Desktop appearance

Noctalia owns the wallpaper palette, bar, dock and shell surfaces. Umbriel owns
layout, blur, borders and animation settings. Home Manager writes their base
configs; Noctalia writes runtime state and rendered palette files itself.

`home/noctalia-settings.nix` keeps the translucent bottom bar visible and reserves
space. `home/umbriel.nix` keeps the rounded, blurred dwindle/stacking desktop and
160% laptop scaling. Change wallpaper, theme mode or power profile in Noctalia.

Kitty and Umbriel include the two palette files configured in `home/noctalia.nix`.
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

Greeter synchronization is disabled because Ly handles login. The declarative
config/runtime-state split and optional palette includes already match the
current docs. Keep GUI overrides in state: resetting a changed setting in the UI
is preferable to introducing another configuration rewrite service.

For native installs, update Umbriel and Noctalia with the distro package manager
before using newly introduced options. The Nix launcher still manages dotfiles
only. Run both validators after native package updates; CI checks the NixOS and
native files against the locked binaries.
