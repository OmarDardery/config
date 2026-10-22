# Debian and Fedora desktop installation

Run the installer from a checkout as your normal user. First edit
`nixos/profile.nix` for your username, home directory and checkout path. The
shipped profile is `oad`, `/home/oad/config/nixos`, `x86_64-linux`.

```sh
cd ~/config
bash debian-setup.sh  # Debian 13 Trixie or Sid
# OR
bash fedora-setup.sh  # Conventional Fedora 44+, not Atomic/rpm-ostree
```

The distribution scripts in this directory perform the following steps:

1. Add the matching upstream-documented desktop repository and install native
   Noctalia, Umbriel, Umbriel's portal and Noctalia Greeter.
2. Install Firefox/Firefox ESR, Kitty, Thunar and its plugins, media/document/office
   tools, capture utilities, fonts, shell basics and the distribution's multi-user
   Nix packages. Fedora also installs native Yazi and Starship from Terra.
3. Build and activate `<profileName>-desktop` through Home Manager, backing up
   conflicting unmanaged files with a timestamped suffix. Home Manager installs
   only LazyVim/VSCodium and their private dependencies, and writes dotfiles.
4. Run `desktop-apply` and install a native user unit to repeat it at graphical
   login. Enable flakes in the managed user Nix configuration. Debian's `batcat`
   and `fdfind` receive user-local `bat` and `fd` links when those names are free.
5. Merge greetd and greeter TOML, select Umbriel, initialize packaged greeter state
   and grant only this active local account the upstream appearance-sync action.
   Existing custom settings/comments are retained; old greetd autologin is removed
   so it cannot bypass the greeter. Changed system files receive `.before-config`
   backups, with numbered backups on subsequent runs.
6. Disable the previous display manager's boot enablement and enable greetd for
   the next boot, after editor/dotfile activation succeeds. The script does not
   explicitly stop the running display manager or start greetd in the active
   session. Package maintainer scripts may perform their normal service actions.
   Reboot after setup and select Umbriel.

Both installers use the packaged `noctalia-greeter-session` wrapper and preserve
packaged PAM configuration. They do not alter Fedora Authselect or SELinux, change
GPU drivers, replace network configuration, remove other desktop environments or
uninstall applications. Existing drivers must support the native Wayland stack.
A failed package download/build stops setup; rerun after resolving the failure.
Native package versions follow their repositories; they are not pinned by the Nix
lock file. A fresh real-machine login remains necessary to verify graphics/PAM.

## Sources and updates

- [Noctalia installation](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Umbriel installation](https://docs.noctalia.dev/umbriel/installation/)
- [Greeter installation](https://docs.noctalia.dev/greeter/installation/)
- [Terra repository configuration](https://github.com/terrapkg/subatomic-repos/blob/main/terra.repo)
- [Debian Nix setup](https://packages.debian.org/trixie/nix-setup-systemd)
- [Fedora Nix daemon](https://packages.fedoraproject.org/pkgs/nix/nix-daemon/)

Debian uses NickH's Noctalia APT repository; Fedora uses the official Fedora
Noctalia package plus Terra's Umbriel/portal nightly and greeter packages. These
third-party repositories are documented by upstream; they are not all maintained
by Debian/Fedora or the Noctalia team. Package/metadata signature checks stay
on. No remote shell installer is piped into a shell.

`update` switches the selected Nix profile and updates Flatpaks. Upgrade native
applications and the host through APT/DNF. Other optional CLI tools can be
installed through the host package manager; shell integrations check for their
commands before starting. Debian does not add an extra repository solely for
Yazi or Starship. `nixos/native/desktop.sh` delegates to the matching full installer
for compatibility; it is no longer a package-command printer.

After changing desktop preferences, run `desktop-apply` or log in again. Runtime
wallpaper, palette algorithm and dark/light mode remain writable. Noctalia's
**Security → Noctalia Greeter → Auto-Sync / Sync Now** copies appearance to the
login screen; no personal home directory is exposed to the greeter.
