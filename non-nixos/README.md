# Standalone Linux configuration

Install Nix and Flatpak through your distro first, then run:

```sh
nix --extra-experimental-features 'nix-command flakes' run github:OmarDardery/config
```

Home Manager manages user dotfiles, the Bibata cursor and user Flatpaks. The
application list is in `home/flatpak.nix`: Zen, Xournal++, LibreOffice, Steam,
ProtonPlus, OrcaSlicer and Discord (availability varies by architecture).
Flatpaks install under the current user; no sudo is used during activation.
The distro supplies the compositor, shell, terminal, editors, Flatpak and drivers.

The Ly Matrix configuration is provided at `~/.config/ly/config.ini` for review.
Ly is a system display manager and normally reads `/etc/ly/config.ini`; installing,
enabling and applying that system configuration requires distro administration.

Edit this checkout and use `config-apply` to reapply, or `up` to update the
standalone lock file first. Existing user Flatpaks and application data are not
removed. Log out and back in for cursor and desktop integration changes.
