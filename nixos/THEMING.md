# Upstream theming and terminal tools

## Lunaria-inspired glass desktop

The [LunariaOS introduction](https://www.youtube.com/watch?v=sP7BDzFxr7s) and
[official previews](https://lunariaos.com/) inspire rounded cards, fine outlines
and an activity capsule for media. This keeps the existing bottom bar and right
dock rather than replacing Noctalia or importing a new desktop environment.
The previews are simulated; the configuration uses native Noctalia controls.

The shell uses wallpaper-tinted frosted glass: a 46% opaque floating bottom bar,
a 52% opaque right dock with hover magnification and running-app dots, glass
panels, and translucent notification/volume cards. Windows have 20px corners,
thin palette-driven borders and soft offset shadows. Kitty uses an 84% opaque
background with live blur; its text stays fully opaque. Applications retain
their own content opacity so documents and games stay readable.

Umbriel uses a restrained opening scale, a faster shrink/fade on close,
smooth workspace slides and rigid pointer dragging. Move and resize use
the same spring to keep tiled reflows aligned. The scratchpad adds a blurred,
dimmed backdrop. Noctalia animates its own panels; compositor layer animations
stay at their upstream default to avoid animating the shell twice. Wallpaper
changes choose between fade, disc and melt, while the lockscreen uses fade/zoom.
This is native transparency and blur rather than a screen-refraction shader.

After merging, pull, rebuild and reboot. The graphical login service runs
`desktop-apply` automatically to reconcile saved shell overrides (with a backup).
It also clears old per-monitor bar/dock opacity overrides, which previously
survived reconciliation and could make glass surfaces opaque. Monitor positions,
enabled states, custom bars, wallpaper, palette and light/dark choices survive.
The shell blur threshold is 0.1 so the translucent surfaces still receive blur.
Validate on the host:

```sh
noctalia config validate ~/.config/noctalia/config.toml
umbriel config validate -c ~/.config/umbriel/config.toml
```

The locked inputs' full rendering/config check is
`nix build ./nixos#checks.x86_64-linux.theme-rendering` from the repository root.
On a slower GPU, reduce `appearance.blur.passes` to 2 in `home/umbriel.nix`.
**Mod+O** opens overview,
**Mod+Ctrl+Space** reveals the scratchpad, and **Mod+A** opens the floating
control center.

## Sharp rendering with a readable UI

`lib/display.nix` sets the laptop UI scale to 1.5. The panel still runs at
2560×1600 at 165 Hz; the HDMI display stays at 1920×1080 and 100%. Its position
follows the scaled laptop width so changing the scale does not leave a gap.

Native Wayland applications receive the output scale. Xwayland keeps
`xwayland_native_resolution = true` so games retain the panel's physical
resolution. That deliberately stops compositor upscaling of X11 windows;
applications must scale their UI themselves. Umbriel's XSETTINGS manager stays
enabled. A narrowly scoped X resource (`Xft.dpi = 144`, merged by `xrdb` at
session startup) also covers Xlib/SDL clients which read font DPI there instead.
No global `GDK_SCALE` or `QT_SCALE_FACTOR` is added, avoiding double scaling.

Steam's package additionally sets `STEAM_FORCE_DESKTOPUI_SCALING=1.5` on the
laptop, following the shared scale. This scales the desktop client, preserving
the game's available resolutions. Valve documents the override and SDL's
primary-monitor query in [issue #5460](https://github.com/ValveSoftware/steam-for-linux/issues/5460).
This is one X11 scale across outputs, so Steam/legacy X11 apps can look larger
on the 100% HDMI display. Wayland apps retain per-output scaling. Games' HUDs
remain controlled by each game's settings.

Reboot after rebuilding so the X11 DPI and Steam process environment are fresh.
Check `xrdb -query` for `Xft.dpi: 144` and confirm Steam's UI size. If Steam
remains tiny, check for a user-created `steam.desktop` pointing at an older
store path or conflicting `-forcedesktopscaling` launch argument. Flatpak apps
with their own saved scaling overrides may need those overrides removed; this
change does not overwrite sandbox-specific preferences.

Home Manager generates Noctalia and Umbriel dotfiles without installing either
application. NixOS installs them through native system/application modules; other
distributions install their own packages. Template
files come directly from the locked Noctalia and community-template inputs;
`home/noctalia-templates.nix` contains their output paths and Nix integration.
The official [user-template API](https://docs.noctalia.dev/noctalia/theming/app-theming/)
keeps generated colors writable without asking apply scripts to modify Nix store
symlinks. GTK/Qt/Starship use Noctalia's built-in integrations. Umbriel now uses
Noctalia's shipped palette template rather than a separately maintained copy.

## Live wallpaper and palette choices

Open the wallpaper picker with **Mod+Alt+W**. Open theme settings directly with
**Mod+Ctrl+Alt+W** and choose the wallpaper-generation algorithm there (Material
3 variants, Faithful, Vibrant, Soft, Muted, and others supplied by Noctalia).
**Mod+Alt+D** toggles light/dark mode. These choices are saved in Noctalia's
writable state and survive rebuilds; Nix declares no selected desktop wallpaper
or generator. Wallpaper-derived colors update the shell and enabled app templates.
Some applications require reopening to display their new colors.

`~/Pictures/Wallpapers` is a writable directory. Add personal images normally;
bundled samples are individual links and existing personal files are preserved.
Home Manager removes its former whole-directory link during the first migration.
Initial missing app palettes use a saved image/algorithm when available, otherwise
the first available personal/sample image and Noctalia's own algorithm default.
This bootstrap does not save or change the selected wallpaper. Existing palettes
are never overwritten by desktop initialization. Noctalia Greeter can sync the desktop appearance without rebuilding.

The [43PR setup linked from the video](https://github.com/43PR/dotfiles) inspired
the floating bar and integrated wallpaper/color workflow. Its Arch
installer, extra shell and Hyprland-specific configuration are not imported.

[Stylix was reviewed](https://nix-community.github.io/stylix/configuration.html).
Its normal image-derived palette is generated during a Nix build; it is useful
for a fixed declarative Base16 theme. Here Noctalia remains the single live color
owner, avoiding overlapping GTK, Kitty and editor configuration. No additional
theming daemon or rebuild-on-wallpaper-change mechanism is installed.

## Application support

| Apps | Source | Integration |
| --- | --- | --- |
| Thunar, Papers, File Roller, Proton VPN, GTK utilities | Noctalia GTK 3/4 | Generated CSS imports |
| FreeCAD, Wireshark, KDE Connect, Qt utilities | Noctalia KColorScheme | Native KDE platform theme and Breeze |
| Kitty, Umbriel, Btop | Shipped templates | Writable palette/theme files; native reload where supported |
| Starship | Built-in integration | Native prompt palette |
| LazyVim, VSCodium, Yazi, Fzf, Lazygit | Community templates | Existing native theme loaders/watchers |
| Zen, Steam/Millennium | Community templates | Existing profile-aware adapters |
| OpenCode | Community templates | Native theme directories and declarative preferences |
| GIMP | Community CSS | Personal override CSS; GIMP path follows the installed version |
| LibreOffice | Community ColorScheme extension | Apply script staged in writable cache; skips installation while Office is open |

There is no matching upstream template for every application. The official
Discord client does not expose these CSS themes without modifications; no client
injector or fork is installed. Apps without a matching template keep their native
appearance and inherit GTK/Qt/terminal colors where supported. Rendering CSS does
not guarantee every application widget honors it.

Run `desktop-apply` after installing the native desktop to initialize missing
palette files in one render. NixOS runs it at graphical login. Existing generated files are preserved. No application apply
hooks run during activation. Later Noctalia palette changes render the templates
and run their configured hooks. Some applications need a restart to read colors.

For GIMP, use its Default base theme. For LibreOffice, close Office and run
`noctalia-apply-libreoffice-theme`, then select Noctalia in **Tools → Options →
LibreOffice → Application Colors**. The upstream extension installer also runs on
palette changes, but defers while Office is open. Closing Office alone does not
retry a deferred installation. The helper uses upstream files.

The six curated plugins still use the official source API. Three integration
patches remain necessary: Screen Toolkit's runtime compatibility, Nix Monitor's
safe asynchronous processes, and Game Launcher's prebuilt helper in a read-only
store. These are documented patches to upstream community plugins, not an
alternative shell or compositor. Updating their explicit input pins remains a
reviewed flake change.

## Kitty and Yazi

Kitty opens Zsh directly; use its native splits and tabs for terminal workspaces.

Yazi remains the file browser. `y` returns the shell to the directory selected
when Yazi exits; `yazi` runs it without changing the shell's working directory.
Natural sorting and directories-first ordering use upstream Yazi settings.

| Desktop binding | Action |
| --- | --- |
| Mod+T | Kitty with Zsh |
| Mod+Shift+E | Yazi directly in Kitty |
| Mod+E | Thunar |

## Login screen

Noctalia Greeter v1.7.0 uses the official project flake/module, sharing the system
Nixpkgs input. It replaces GDM; greetd launches the packaged session wrapper and
retains native keyring PAM integration. The greeter's default user, Umbriel session
and US/Arabic keyboard layouts are declarative. Wallpaper, palette and theme mode
are omitted so synced appearance remains writable state.

In Noctalia, open Settings → Security → Noctalia Greeter → Sync Now. Enable
Auto-Sync Greeter there to follow later wallpaper/palette/font changes. The module
allows only the configured local user's active session to invoke the constrained
appearance-sync action without a password; general administrative and legacy
helper actions still require authentication. No custom sync script or Polkit rule
is maintained in this repository.

The upstream module owns `/var/lib/noctalia-greeter/greeter.toml`; GUI/synced values
live in `sync.toml` and survive rebuilds. No home-directory access is granted to the
greeter. Sync copies the chosen wallpaper into its own state directory.

Build the system first. For the first display-manager replacement, activate from
a TTY or use `sudo nixos-rebuild boot --flake ~/config/nixos#nixos` and reboot;
restarting the login service can end a graphical session. After boot, verify
`systemctl status greetd`, logging into Umbriel, keyring unlocking, logout and
appearance sync. Review failures with `journalctl -b -u greetd`.

References: [official NixOS setup](https://docs.noctalia.dev/greeter/installation/),
[appearance sync](https://docs.noctalia.dev/greeter/sync/).
