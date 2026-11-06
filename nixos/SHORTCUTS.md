# NixOS desktop shortcuts

`Mod` is Super. `Mod+Shift+Escape` opens Umbriel's live cheatsheet, including
bindings inherited from upstream. The same physical shortcuts work with English
or Arabic input. Power actions are available from the session menu.

Open `Mod+O` and type to launch applications directly from the overview.

The bottom bar stays visible and reserves space. The right dock reveals on hover.
The bar shows essential status; occasional tools remain in panels and shortcuts.

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

| Shortcut | Action |
| --- | --- |
| Mod+D | Cycle **dwindle → stacking → dwindle** |
| Mod+Alt+1 / Mod+Alt+2 | Select dwindle / stacking directly |
| Mod+Left/Right or H/L | Focus horizontally |
| Mod+J/K or Mod+WheelDown/Up | Focus windows vertically |
| Mod+Up/Down / Mod+Tab | Previous-next workspace / previous workspace |
| Mod+1…9 / Mod+Ctrl+1…9 | Select a numbered workspace / move column there |
| Mod+Ctrl+arrows or H/J/K/L | Move columns or windows |
| Mod+Shift+arrows | Focus another monitor |
| Mod+Ctrl+Shift+arrows | Move column to another monitor |
| Mod+Home/End / Mod+Ctrl+Home/End | Focus first-last column / move it there |
| Mod+Alt+Left/Right | Select previous-next tab |
| Mod+Return / Mod+Shift+T | Toggle floating / focus floating-tiled windows |
| Mod+F / Mod+Shift+F or Mod+Ctrl+F / Mod+M | Fullscreen / maximize / maximize to edges |
| Mod+C / Mod+Ctrl+C | Center the focused column |
| Mod+W / Mod+P | Toggle column tabs / pin the window |
| Mod+R / Mod+Shift+R / Mod+Alt+R | Next width / previous width / height preset |
| Mod+Minus/Equal / Mod+Shift+Minus/Equal | Adjust width / height |
| Mod+Alt+T | Toggle the dwindle split direction |
| Mod+Comma/Period | Consume or expel a window left-right |
| Mod+Ctrl+Comma/Period | Pull a window from the left-right column |
| Mod+Shift+Space | Send window to scratchpad |
| Mod+Ctrl+Space / Mod+Alt+Space / Mod+Alt+Tab | Show-hide / restore / cycle scratchpad |
| Mod+O / Mod+Q | Overview / close window |

Horizontal wheel actions focus horizontally; adding Ctrl moves the column.
Shift+vertical wheel has the same horizontal behavior. Ctrl+vertical wheel
moves the column between workspaces. Master is absent from the configured cycle
and direct shortcuts.

Stacking opens overlapping windows. Drag title bars to move them and use the
edge/corner previews to snap to halves or quarters. Switching back to dwindle
re-tiles layout-floated windows. `Mod+Return` applies to tiling layouts; Umbriel
rejects toggling floating in stacking.

## Capture

Noctalia handles screenshots directly:

| Shortcut | Action |
| --- | --- |
| Mod+S / Print / F6 | Capture a region |
| Shift+Print / Ctrl+Shift+2 | Capture the screen |
| Ctrl+Print / Ctrl+Shift+3 | Capture the focused window |
| Alt+Print | Annotate |

The Screen Toolkit plugin and its OCR/recording submap are removed.

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
