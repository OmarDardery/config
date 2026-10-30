# Desktop configuration

Personal NixOS desktop with Umbriel, Noctalia, Kitty, Zsh, Yazi, Neovim and
VSCodium. Home Manager also provides the same dotfiles on Debian and Fedora.

## Setup

Edit [nixos/profile.nix](nixos/profile.nix) for your account and checkout path.
The defaults are `oad`, `/home/oad/config/nixos`, host `nixos`.

```sh
cd ~/config
bash nixos-setup.sh
# Or, on another distribution:
bash debian-setup.sh
bash fedora-setup.sh
```

NixOS setup copies the machine's generated hardware configuration, builds, then
switches the system. Review `nixos/hardware.nix` before using another machine:
it contains this laptop's NVIDIA/PRIME and storage settings.

## Editors

Neovim uses a small [LazyVim starter](https://github.com/LazyVim/starter).
VSCodium is the regular package with Nix and EditorConfig extensions. Both retain
the Noctalia theme and Nix formatting/completion.

No Python environments, notebook kernels, scientific libraries, compiler suites,
debug adapters or AI extensions are provisioned for the editors. Neovim's Python,
Ruby and Node providers are disabled. Lazy manages its plugins in user data;
Mason is disabled so opening an editor does not install a language toolchain.
Add other editor extensions or project dependencies when you need them.

On Debian/Fedora, run `editor-setup` to sync plugins and the two extensions.
It does not run pip or create a Python environment. System utilities still use
their normal runtime dependencies; the system is not intended to be Python-free.

## Optional applications

These bundles default off. Enable any you use in `nixos/configuration.nix`:

```nix
workstation = {
  gaming.enable = true;       # Steam, Millennium, GameMode, ProtonPlus
  engineering.enable = true;  # FreeCAD, Logisim, PlatformIO, webOS, OrcaSlicer
  containers.enable = true;   # WinBoat and socket-activated Docker
  printing.enable = true;     # Printers, scanners and discovery
};
```

Existing Flatpaks, project environments and application data are preserved.

## Daily use

- `up` / `rebuild`: apply the selected system or Home Manager profile.
- `update`: update inputs, apply configuration, then update Flatpaks.
- `desktop-apply`: initialize missing palettes and apply desktop preferences.
- `cnf` / `cconf`: edit or enter the configuration directory.
- `y`: open Yazi and return to the selected directory.
- `ppt2pdf`, `doc2pdf`, `xls2csv`: LibreOffice conversion helpers.

[Configuration layout and deployment](nixos/README.md) ·
[Desktop shortcuts](nixos/SHORTCUTS.md) · [Theming](nixos/THEMING.md) ·
[Backups](nixos/BACKUPS.md) · [Native setup](nixos/native/README.md)
