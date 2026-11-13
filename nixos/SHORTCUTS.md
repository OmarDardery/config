# NixOS desktop shortcuts

`Mod` is Super. `Mod+Shift+Escape` opens Umbriel's live cheatsheet, including
bindings inherited from upstream. The same physical shortcuts work with English
or Arabic input. Power actions are available from the session menu.

Open `Mod+O` and type to launch applications directly from the overview.

The bottom bar stays visible and reserves space. Smart Taskbar (by OmarDardery)
shows the focused application in a compact capsule. Hovering reveals running
applications, with numeric badges for duplicate windows and mouse-wheel navigation
for overflow within a 420px width budget. The old dock and native taskbar are
disabled. Plugin source, enabled state and appearance are declared in
`home/noctalia-settings.nix`; Noctalia downloads the source itself.

## Apps and shell

| Shortcut | Action |
| --- | --- |
| Mod+T / Mod+B / Mod+E | Kitty / Zen / Thunar |
| Mod+grave / Mod+Ctrl+Return | Terminal / calculator scratchpad |
| Mod+Ctrl+P / Mod+Ctrl+Shift+P | Start / end presentation mode |
| Mod+Shift+E | Yazi directly in Kitty |
| Mod+I / Mod+Ctrl+E | VSCodium / edit the Nix configuration tree |
| Mod+Space | App launcher, search and calculator |
| Alt+Tab | Window switcher; release Alt to activate |
| Mod+A / Mod+Ctrl+S | Control center / Noctalia settings |
| Mod+V / Mod+N | Clipboard history / notifications |
| Mod+Shift+N / Mod+Ctrl+N | Toggle Do Not Disturb / dismiss active notifications |
| Mod+Alt+L / Mod+Shift+Q | Lock / session and power menu |
| Mod+Alt+W / Mod+Alt+D | Wallpaper chooser / light-dark theme |
| Mod+Ctrl+Alt+W | Theme settings: wallpaper palette algorithm |
| Mod+Alt+C / Mod+Alt+N | Caffeine / force night light |
| Mod+Alt+P | Cycle power profile |
| Mod+Alt+A / Mod+Alt+B | Audio / Bluetooth controls |
| Mod+Alt+E | Emoji picker |
| Mod+Shift+D / Mod+Shift+M | Display configuration / laptop HDMI mirror |
| Mod+Ctrl+Alt+T | OpenTabletDriver settings (laptop) |
| Mod+Shift+P | Turn displays off |
| Mod+Escape | Toggle shortcut passthrough for the focused app |
| Mod+Ctrl+Shift+R | Reload Umbriel configuration |

Media, microphone, volume and brightness keys remain available while locked.
The power button locks first. `Ctrl+Alt+Delete` quits the compositor session.

## Windows and layouts

Stacking is the default, with overlapping and resizable windows. Master is the
optional 60/40 layout, with the primary window on the left.

| Shortcut or gesture | Action |
| --- | --- |
| Drag title bar | Move a window |
| Drag edge or corner | Resize a floating window |
| Super + left-drag | Move from anywhere on a window |
| Super + right-drag | Resize from anywhere on a window |
| Double-click title bar / double Super + right-click | Maximize or restore |
| Drag to edge or corner | Snap to half or quarter of the available screen |
| Mod+F | Fullscreen |
| Mod+Shift+F | Maximize or restore |
| Mod+Minus/Equal | Decrease/increase width 5% |
| Mod+Shift+Minus/Equal | Decrease/increase height 5% |
| Mod+Alt+1 / Mod+Alt+2 | Stacking / master |
| Mod+D | Toggle stacking and master |
| Mod+Left/Right or H/L | Focus horizontal neighbor |
| Mod+J/K | Focus vertical neighbor |
| Mod+Alt+Left/Right | Focus tabs |
| Mod+W | Toggle tabs |
| Mod+1…9 / Mod+Ctrl+1…9 | Switch workspace / move window group |
| Mod+Up/Down | Previous/next workspace |
| Mod+Shift+arrows | Focus another monitor |
| Mod+Q / Mod+O | Close / overview |

Clicking a window activates it; hovering does not steal focus.
Mouse resizing and snapping are built into Umbriel.

## Capture

| Shortcut | Action |
| --- | --- |
| Print | Capture region |
| Shift+Print | Capture full screen |
| Ctrl+Print | Capture window |
| Alt+Print | Annotate |

## XP-Pen Deco mini7

The optional `assets/tablet-settings.json` preset has these express keys, in
OpenTabletDriver’s order. Import or configure it manually; rebuilds do not modify
your live tablet settings:

| Keys | Action |
| --- | --- |
| 1 / 2 | Zoom in / out (`Ctrl+Equal` / `Ctrl+Minus`) |
| 3 / 4 | Up / down |
| 5 / 6 | Paste / copy |
| 7 / 8 | Undo / redo (`Ctrl+Z` / `Ctrl+Shift+Z`) |

Set pen-button actions in OpenTabletDriver and Xournal++ Preferences → Stylus.
Those preferences are managed by the applications themselves.

## Kitty

Kitty uses Ctrl+Shift, keeping terminal commands separate from desktop controls.

| Shortcut | Action |
| --- | --- |
| Ctrl+Shift+Enter | New terminal pane in the current directory |
| Ctrl+Shift+D / Ctrl+Shift+Alt+D | Horizontal / vertical split |
| Ctrl+Shift+T / Ctrl+Shift+N | New tab / OS window in the current directory |
| Ctrl+Shift+J/K | Next-previous pane |
| Ctrl+Shift+Z | Focus the current pane with stack layout; press again to return |
| Ctrl+Shift+U | Open a URL using keyboard hints |
| Ctrl+Shift+C/V | Copy-paste |
| Ctrl+Shift+H | Open scrollback in the pager; use `/` to search |
| Ctrl+Shift+PageUp/PageDown | Previous-next tab |
| Ctrl+Shift+W / Ctrl+Shift+Q | Close pane / tab |
| Ctrl+Shift+F5 | Reload configuration |
| Ctrl+Shift+F2 | Edit the shared kitty.conf in a Neovim overlay |

Kitty's command palette exposes remaining built-in actions. Settings and
shortcuts live in `../non-nixos/dotfiles/kitty/kitty.conf`, with NixOS integration
in `home/kitty.nix`. Colours come from Noctalia's generated palette.

## Editors

Both editors start with Nix support and ordinary built-in themes. Use LazyVim's built-in
which-key menu for navigation; install language tools and extensions as needed.
Notebook and custom AI/debugger shortcuts are no longer part of this config.
