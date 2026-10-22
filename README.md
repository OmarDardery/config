# Desktop configuration

Shared dotfiles, LazyVim and VSCodium across Linux distributions, with separate
NixOS application and system modules.

| Profile | Home Manager | Application/service installation |
| --- | --- | --- |
| NixOS `nixos` | Dotfiles, both editors and their private dependencies | NixOS modules |
| Linux `oad` | Shared dotfiles and both editors | Native distribution |
| Linux `oad-desktop` | Also Noctalia/Umbriel dotfiles and dynamic editor themes | Native distribution |

Home Manager does not install a shell, terminal, compositor, greeter, CLI suite,
Flatpaks or user services. It configures native tools without replacing them.
Editor dependencies remain in Nix and are available inside the editors.

## Deploy

Edit [nixos/profile.nix](nixos/profile.nix) for your account and checkout path.
The defaults are `oad`, `/home/oad/config/nixos`, host `nixos`. Hardware files
are specific to the laptop and need review on another NixOS machine.

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate
```

Other distributions build `oad` by default. Install native desktop applications
separately using [the native setup guide](nixos/native/README.md), then select
`--profile oad-desktop` if you want their dotfiles as well. Use
`--backup-extension bak` when migrating conflicting unmanaged files.

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
