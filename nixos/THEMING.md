# Upstream theming and terminal workspaces

Noctalia and Umbriel use their upstream Home Manager/NixOS modules. Template
files come directly from the locked Noctalia and community-template inputs;
`home/noctalia-templates.nix` contains their output paths and Nix integration.
The official [user-template API](https://docs.noctalia.dev/noctalia/theming/app-theming/)
keeps generated colors writable without asking apply scripts to modify Nix store
symlinks. GTK/Qt/Starship use Noctalia's built-in integrations. Umbriel now uses
Noctalia's shipped palette template rather than a separately maintained copy.

| Apps | Source | Integration |
| --- | --- | --- |
| Thunar, Papers, File Roller, Proton VPN, GTK utilities | Noctalia GTK 3/4 | Generated CSS imports |
| FreeCAD, Wireshark, KDE Connect, Qt utilities | Noctalia KColorScheme | Native KDE platform theme and Breeze |
| Kitty, Umbriel, Btop | Shipped templates | Writable palette/theme files; native reload where supported |
| Starship | Built-in integration | Native prompt palette |
| LazyVim, VSCodium, Yazi, Fzf, Lazygit | Community templates | Existing native theme loaders/watchers |
| Zen, Steam/Millennium | Community templates | Existing profile-aware adapters |
| Zellij, OpenCode | Community templates | Native theme directories and Home Manager settings |
| GIMP, Inkscape | Community CSS | Personal override CSS; GIMP path matches the pinned 3.0 series |
| Fastfetch | Community colors/apply script | Disposable color processing plus native CLI overrides; user JSONC stays intact |
| LibreOffice | Community ColorScheme extension | Apply script staged in writable cache; skips installation while Office is open |

There is no matching upstream template for every application. The official
Discord client does not expose these CSS themes without modifications; no client
injector or fork is installed. Apps without a matching template keep their native
appearance and inherit GTK/Qt/terminal colors where supported. Rendering CSS does
not guarantee every application widget honors it.

Missing palette files are initialized in one render before Home Manager links the
new configuration. Existing generated files are preserved. No application apply
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

## Zellij and Yazi

Kitty's normal shell starts Zellij. Its panes run Zsh without shell auto-start,
so opening a pane does not start another multiplexer. The upstream compact layout
and built-in plugins provide tabs, panes, session management and persistent
sessions. Closing a terminal detaches the session. Restore one with `za`; `zl`
lists sessions. `zdev` opens Code, Files, Git and Shell tabs in the current folder.

Zellij starts locked so editor shortcuts pass through. Press **Ctrl+G** to unlock,
then use its visible hints: **Ctrl+P** for panes, **Ctrl+T** for tabs, **Ctrl+O**
for sessions, and **Ctrl+G** to lock again. Colors use the generated Noctalia
KDL theme; already-running sessions may need a config reload/new session to read
a changed theme. Portable Home Manager uses Zellij's built-in theme.

Yazi remains the file browser. `y` returns the shell to the directory selected
when Yazi exits; `yazi` runs it without changing the shell's working directory.
Natural sorting and directories-first ordering use upstream Yazi settings.

| Desktop binding | Action |
| --- | --- |
| Mod+T | Kitty with Zellij |
| Mod+Ctrl+T | Plain Kitty/Zsh |
| Mod+Shift+E | Yazi directly in Kitty |
| Mod+E | Thunar |

Zellij 0.45 adds Kitty graphics support, but
[Yazi documents remaining preview issues](https://yazi-rs.github.io/docs/next/image-preview/#zellij-users).
Use the direct Yazi shortcut for reliable native Kitty previews; terminal identity
variables are not spoofed. This path also stays available when troubleshooting a
multiplexer session.
