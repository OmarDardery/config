# Standalone Linux configuration

Install Nix and Flatpak through your distro first, then run:

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

Home Manager manages user dotfiles, the Bibata cursor and user Flatpaks. The
application list is in `home/flatpak.nix`: Zen, Xournal++, LibreOffice, Steam,
ProtonPlus, OrcaSlicer, Discord, Papers, File Roller and KeePassXC
(availability varies by architecture).
Flatpaks install under the current user; no sudo is used during activation.
The distro supplies Neovim, VSCodium, Zsh, Starship, Kitty, the compositor,
Flatpak and drivers. Home Manager manages their dotfiles without installing the
applications or changing the account login shell.

If an earlier configuration set your login shell to the Nix profile's Zsh, change
it to a distro-provided shell before applying this configuration, or removing that
profile package can leave the account with an unavailable login shell.

The Noctalia Greeter template is managed at `~/.config/noctalia-greeter/greeter.toml`.
The greeter reads `/var/lib/noctalia-greeter/greeter.toml`; installing the greeter,
configuring greetd, and applying the template there require system administration.
The default session is Umbriel, if its desktop entry is installed.

Edit this checkout and use `config-apply` to reapply, or `up` to update the
standalone lock file first. Existing user Flatpaks and application data are not
removed. Log out and back in for cursor and desktop integration changes.
