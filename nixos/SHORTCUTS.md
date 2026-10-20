# NixOS desktop shortcuts

`Mod` is Super. `Mod+Shift+Escape` opens Umbriel's live cheatsheet, including
bindings inherited from upstream. The same physical shortcuts work with English
or Arabic input. Power actions are available from the session menu.

Open `Mod+O` and type to launch applications directly from the overview.

The bottom bar and right-hand dock hide on occupied workspaces and reveal at the
screen edge without reserving window space. Hover Screen Toolkit in the bar to
expand clipboard, phone and Pomodoro; their shortcuts work while collapsed.

## Apps and shell

| Shortcut | Action |
| --- | --- |
| Mod+T / Mod+B / Mod+E | Kitty / Zen / Thunar |
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
| Mod+Alt+V | Tailscale peers, VPN and exit-node manager |
| Mod+Alt+A / Mod+Alt+B | Audio / Bluetooth controls |
| Mod+Alt+E | Emoji picker |
| Mod+Alt+G / Mod+Alt+M / Mod+Alt+O | Games / phone / Pomodoro |
| Mod+Shift+D / Mod+Shift+M | Display configuration / laptop HDMI mirror |
| Mod+Shift+P | Turn displays off |
| Mod+Escape | Toggle shortcut passthrough for the focused app |
| Mod+Ctrl+Shift+R | Reload Umbriel configuration |

Media, microphone, volume and brightness keys remain available while locked.
The power button locks first. `Ctrl+Alt+Delete` quits the compositor session.

## Windows and layouts

| Shortcut | Action |
| --- | --- |
| Mod+D | Cycle **dwindle → scrolling → dwindle** |
| Mod+Alt+1 / Mod+Alt+2 | Select dwindle / scrolling directly |
| Mod+Left/Right or H/L | Focus horizontally |
| Mod+J/K or Mod+WheelDown/Up | Focus rows or tabs |
| Mod+Up/Down / Mod+Tab | Previous-next workspace / previous workspace |
| Mod+1…9 / Mod+Ctrl+1…9 | Switch workspace / move column there |
| Mod+Ctrl+arrows or H/J/K/L | Move columns or rows/tabs |
| Mod+Shift+arrows | Focus another monitor |
| Mod+Ctrl+Shift+arrows | Move column to another monitor |
| Mod+Home/End / Mod+Ctrl+Home/End | Focus first-last column / move it there |
| Mod+Alt+Left/Right | Select previous-next tab |
| Mod+Return / Mod+Shift+T | Toggle floating / focus floating-tiled windows |
| Mod+F / Mod+Shift+F / Mod+M | Maximize / fullscreen / maximize to edges |
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

## Capture

`Mod+S` opens Screen Toolkit. It supports Tab, arrows, Enter and Escape.
`Print` or `F6` captures a region; Shift+Print or Ctrl+Shift+2 captures the screen;
Ctrl+Print or Ctrl+Shift+3 captures the focused window; Alt+Print annotates.

Press **Mod+Shift+S**, release it, then:

| Key | Action |
| --- | --- |
| C / O / Q | Colour picker / OCR / QR reader |
| P / L / M | Palette / lens / measurement |
| A | Annotate a region |
| R / F / G | Record region as MP4 / screen as MP4 / region as GIF |
| S / V | Stop recording / save result |
| F1 / Escape | Cheatsheet / cancel the shortcut group |

The group exits after an action. Invoke it again to stop/save a recording.

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
| Ctrl+Shift+F2 | Edit home/kitty.nix in a Neovim overlay |

Kitty's command palette exposes remaining built-in actions. Settings and
shortcuts belong in `home/kitty.nix`; colours come from Noctalia's generated palette.
