# Desktop appearance

Noctalia owns the wallpaper palette, bar, dock and shell surfaces. Umbriel owns
layout, blur, borders and animation settings. Home Manager writes their base
configs; Noctalia writes runtime state and rendered palette files itself.

`home/noctalia-settings.nix` keeps the translucent bottom bar visible and reserves
space. `home/umbriel.nix` keeps the rounded, blurred dwindle/scrolling desktop and
160% laptop scaling. Change wallpaper, theme mode or power profile in Noctalia.

Kitty and Umbriel include the two palette files configured in `home/noctalia.nix`.
Missing files on the first start use native defaults. Select a wallpaper in
Noctalia to render them; no startup service seeds or rewrites settings. Bundled
wallpapers are available under `~/.local/share/noctalia/wallpaper-samples/`.

GTK, Qt and Starship use Noctalia's built-in templates. Editors, browser and Steam
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
