# Desktop configuration

Shared Umbriel, Noctalia, Kitty, Zsh, VSCodium and LazyVim configurations across
Linux distributions, with separate application installation.

| Profile | Home Manager | Application/service installation |
| --- | --- | --- |
| NixOS `nixos` | All dotfiles; both editors and their private dependencies | NixOS modules install the desktop applications |
| Other Linux `oad` / `oad-desktop` | All six configurations, shortcuts and themes | Native packages, Lazy/Mason and Codium own installation |

On other distributions Home Manager installs no applications, editor plugins or
language tools. Its profile contains only its internal session-variable helper.
NixOS keeps pinned editor packages/plugins/tooling in Nix. The `oad-desktop` name
is retained for compatibility; both standalone outputs configure the full desktop.

## Lean NixOS defaults

Gaming, engineering apps, WinBoat/Docker, and printing/scanning are now opt-in
bundles in `nixos/configuration.nix`. Enable the `workstation.<bundle>.enable`
options you use before rebuilding. See [the module layout and bundle contents](nixos/ARCHITECTURE.md).
Editors retain their private tools; project toolchains are available with
`nix develop path:./nixos#general` or `#embedded`. Existing application data and
Flatpaks are preserved when a bundle is disabled.

## Deploy

Edit [nixos/profile.nix](nixos/profile.nix) for your account and checkout path.
The defaults are `oad`, `/home/oad/config/nixos`, host `nixos`.

```sh
cd ~/config
bash nixos-setup.sh   # Full NixOS system
# OR, on another distribution:
bash debian-setup.sh  # Debian Trixie/Sid desktop + dotfiles/editors
bash fedora-setup.sh  # Conventional Fedora 44+ desktop + dotfiles/editors
```

On NixOS the installer copies `/etc/nixos/hardware-configuration.nix`, replaces
its local repository counterpart (backing up changes), and applies the full
configuration through `sudo nixos-rebuild switch --flake path:…/nixos#nixos`.
The generated hardware file is ignored by Git and is no longer tracked.
Review `nixos/hardware.nix` separately on different hardware: it still contains
this laptop's NVIDIA/PRIME and extra-storage policy.

Debian/Fedora install the browser, desktop and greeter through APT/DNF, then
apply all shared dotfiles. Editors are native applications too. Reboot to enter the new greeter.
See [native setup details and upstream repositories](nixos/native/README.md).
Run `editor-setup` after native installation for editor plugins and notebook tools.
For a dotfiles-only switch or a build preview, use
`nixos/bootstrap.sh --help`.

Log out and back in after migration to clear old shell/environment settings.
On NixOS, Flatpaks move from the user installation to a system-managed
installation; see [migration notes](nixos/README.md#migration).

## Daily use

- `up` / `rebuild`: switch the selected NixOS or Home Manager profile.
- `update`: update flake inputs, switch configuration, then update Flatpaks.
- `desktop-apply`: initialize missing app themes and reconcile desktop preferences.
- `ppt2pdf` / `ppt2txt`, `doc2pdf` / `doc2txt`, `xls2csv`: native LibreOffice helpers.
- `cnf` / `cconf`: edit or enter the configuration directory.
- `y`: run native Yazi and return to the selected directory.

For project notebooks: `uv add --dev ipykernel`, then `notebook-kernel` from the
project directory. Select the named kernel in VSCodium, or use `<leader>mp` in
LazyVim. Python diagnostics use basic analysis without large inline messages.

[Structure and design](nixos/ARCHITECTURE.md) · [Deployment and migration](nixos/README.md) ·
[Shortcuts](nixos/SHORTCUTS.md) · [Theming](nixos/THEMING.md) · [Performance](nixos/PERFORMANCE.md)
