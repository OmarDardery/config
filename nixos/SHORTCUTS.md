# NixOS desktop shortcuts

`Mod` is Super. `Mod+Shift+Escape` opens Umbriel's live cheatsheet, including
bindings inherited from upstream. The same physical shortcuts work with English
or Arabic input. Power actions are available from the session menu.

Open `Mod+O` and type to launch applications directly from the overview.

The desktop follows macOS conventions: a translucent menu bar at the top (⌘
menu/Spotlight and the focused app on the left, Now Playing in the middle while
media plays, then privacy dots, tray, keyboard layout, volume, Bluetooth, Wi-Fi,
battery, notifications, Control Center and the clock on the right), a magnifying dock at the
bottom with running-app dots and a Launchpad button (it hides while windows are
open; move the pointer to the bottom edge to reveal it), and translucent title bars with
minimize/maximize/close buttons on the right. Click a focused app in the
dock to minimize it. Super+Space and the dock's grid button open the same app
grid (type to search). Clicking the Wi-Fi, Bluetooth or volume icon opens
Control Center; clicking the clock opens notifications. KDE Connect sits in the
menu-bar tray. An empty workspace shows clock, weather and calendar widgets. Rest the pointer in the top-left corner, or swipe up with four
fingers, for Mission Control (overview); swipe with three fingers between
workspaces. Two-finger click opens context menus.

## Apps and shell

| Shortcut | Action |
| --- | --- |
| Mod+T / Mod+B / Mod+E | Kitty / Zen / Luciole |
| Mod+grave / Mod+Ctrl+Return | Terminal / calculator scratchpad |
| Mod+Ctrl+P / Mod+Ctrl+Shift+P | Start / end presentation mode |
| Mod+I / Mod+Ctrl+E | Zed / edit the Nix configuration tree |
| Mod+Space | Spotlight: app launcher, search and calculator |
| Mod+Tab / Alt+Tab | App switcher (most recent first); release the modifier to activate |
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
The power button locks first. `Ctrl+Alt+Delete` opens the session/power menu.

## Windows and layouts

Stacking is the default overlapping, freely resizable desktop layout, like macOS.
Scrolling is the optional niri-like layout: windows form columns on an endless
horizontal strip. Only floating windows can be minimized.

| Shortcut or gesture | Action |
| --- | --- |
| Drag title bar | Move a window |
| Drag edge or corner | Resize a floating window |
| Super + left-drag | Move from anywhere on a window |
| Super + right-drag | Resize from anywhere on a window |
| Double-click title bar / double Super + right-click | Maximize or restore |
| Drag to edge or corner | Snap to half or quarter of the available screen |
| Mod+F / Mod+Ctrl+F | Fullscreen |
| Mod+Shift+F | Maximize or restore |
| Mod+Ctrl+M | Maximize to the screen edges |
| Mod+H / Mod+M / Mod+Alt+M | Hide (minimize) / minimize / restore last minimized |
| Mod+Minus/Equal | Decrease/increase width 5% |
| Mod+Shift+Minus/Equal | Decrease/increase height 5% |
| Mod+Alt+1 / Mod+Alt+2 | Stacking / scrolling |
| Mod+D | Toggle stacking and scrolling |
| Mod+Left/Right, Mod+L | Focus horizontal neighbor |
| Mod+J/K | Focus vertical neighbor |
| Mod+Alt+Left/Right | Focus tabs |
| Mod+W | Toggle tabs |
| Mod+1…9 / Mod+Ctrl+1…9 | Switch workspace / move window group |
| Mod+Up/Down | Previous/next workspace |
| Mod+Ctrl+Tab | Last workspace |
| Mod+Shift+arrows | Focus another monitor |
| Mod+Q / Mod+O | Close / overview |

Focus changes only on click, keybind or activation; hovering over a window does
not focus it.
Mouse resizing and snapping are built into Umbriel.

## Capture

| Shortcut | Action |
| --- | --- |
| Print / Mod+Shift+S / Mod+Shift+4 | Capture region with grim/slurp, save to Pictures/Screenshots and copy |
| Shift+Print / Mod+Shift+3 | Capture full desktop with grim, save and copy |
| Ctrl+Print | Capture focused window through Noctalia |
| Alt+Print / Mod+Shift+5 | Open Noctalia screenshot annotator |

Mod+Shift+3/4/5 replace Umbriel's built-in "move to workspace and follow" for
those three numbers; Mod+Ctrl+3/4/5 still move a window there.

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

Zed and LazyVim both start with Nix support (nixd, nixfmt) and ordinary built-in
themes. Zed runs in vim mode; its command palette is Ctrl+Shift+P. Use LazyVim's
built-in which-key menu for navigation; install language tools and extensions as needed.
Notebook and custom AI/debugger shortcuts are no longer part of this config.
