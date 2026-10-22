# Native applications on other distributions

Home Manager installs LazyVim and VSCodium and writes dotfiles. Install everything
else with the host distribution. The Nix editor closures contain their language
servers, runtimes, extensions and plugin dependencies; these are private to the
editors rather than added to the global application profile.

## Desktop

Use the upstream installation guides:

- [Noctalia](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Umbriel](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/installation.md)
- [Noctalia Greeter](https://docs.noctalia.dev/greeter/installation/)

These projects distinguish official distribution packages from the
community-maintained repositories they document. A repository linked by upstream
is not necessarily maintained by the distribution itself.

On Debian Trixie, Sid or Ubuntu 26.04, first configure the matching Noctalia APT
repository using those instructions and refresh APT metadata. Then review the
separate installation command:

```sh
bash ~/config/nixos/native/desktop.sh --print
bash ~/config/nixos/native/desktop.sh --install
```

The script only invokes package installation. It does not add repositories or
call service-management commands. Packages can perform their normal maintainer
actions; Debian/Ubuntu greeter packages configure greetd during installation. For Fedora, Arch and
openSUSE use the native package instructions in the linked guides; package names
and repository requirements differ, so this script does not guess them.

The desktop preferences assume the configured native applications (including
Kitty, Thunar and its archive/volume plugins). Install those applications or
adapt `home/files.nix` before applying their MIME defaults.

Install Umbriel's portal alongside the compositor. Follow the greeter guide for
its session wrapper, greetd configuration, AccountsService, Polkit, state setup
and display-manager handoff. Keep GPU drivers, PipeWire, printing and system
services owned by the distribution. A Home Manager switch cannot configure these
system integrations on a non-NixOS machine.

After installing the native desktop, opt into its dotfiles:

```sh
bash ~/config/nixos/bootstrap.sh --profile oad-desktop --activate --backup-extension bak
desktop-apply
```

Edit `profile.nix` for another account first. The default `oad` profile leaves
Noctalia/Umbriel, GTK and MIME settings alone. The `oad-desktop` profile writes
them and enables dynamic editor themes, but installs no desktop applications or
services. Run `desktop-apply` again after changing managed desktop preferences;
it initializes missing app palettes and removes conflicting managed state
preferences while preserving runtime wallpaper, algorithm and mode choices.

## Tools used by the dotfiles

Install the tools you use through the distribution's packages. Shell hooks check
for their commands before enabling integrations, so missing optional tools do not
break shell startup.

| Purpose | Commands |
| --- | --- |
| Shell and prompt | `bash`, `zsh`, `starship`, `zoxide`, `fzf`, `direnv` |
| Files and diagnostics | `eza`, `bat`, `btop`, `fastfetch`, `yazi`, `rg`, `fd` |
| Git | `git`, Git LFS, `delta`, `gh`, `lazygit` |
| Helper scripts | Python 3.11+, Bash, coreutils, `flock` |
| Office conversions | `libreoffice` / `soffice`, Python 3 |
| Capture and plugins | `grim`, `slurp`, `wl-copy`, `jq`, `swappy`, `tesseract`, `ffmpeg`, `pactl` |
| Themes | Bibata Modern Classic cursor, JetBrainsMono Nerd Font, GTK/Qt themes |

Some distributions call Bat `batcat` and fd `fdfind`; supply the standard command
names if you use these workflows. Package names are distribution-specific.
Nix itself must already be installed with flakes enabled. `up` uses this flake's
pinned Home Manager CLI through `nix run`, so no global `nh` or Home Manager
installation is necessary. `update` updates this flake and switches only Home
Manager, then updates native Flatpaks when Flatpak is installed. Host OS updates
remain the native package manager's responsibility.

`notebook-kernel` uses the project's `.venv/bin/python`. Install `ipykernel` in
that environment first. The helper itself needs native Python 3; both editors
also include a Nix-packaged copy in their private tool paths.
