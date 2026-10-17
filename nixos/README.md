# Desktop configuration

One shared Home Manager desktop runs on NixOS or an existing Debian/Fedora
installation. `profile.nix` contains identity and deployment paths;
`hardware.nix` and the generated `hardware-configuration.nix` describe the laptop.

## Where settings belong

| Location | Owns |
| --- | --- |
| `configuration.nix` | NixOS entry point and original state version |
| `system/base.nix` | Boot, locale, user account, Home Manager wiring, journal limits |
| `system/networking.nix` | NetworkManager, Tailscale and KDE Connect firewall policy |
| `system/nix.nix` | Nix build limits, cache, garbage collection and optimisation |
| `system/desktop.nix` | Login sessions, portals, host privileges, audio, printing/scanning and power |
| `system/development.nix` | Docker, foreign-binary loader and PlatformIO device rules |
| `system/gaming.nix` | GameMode privileges and Steam device integration |
| `home/apps.nix` | Browser, chat, office, media viewers, image editors and scanner UI |
| `home/files.nix` | Thunar/plugins, archives, removable drives, user folders and file associations |
| `home/engineering.nix` | Blender, FreeCAD, Logisim, WinBoat and webOS tools |
| `home/terminal.nix` | Kitty migration and command-line utilities/diagnostics |
| `home/desktop.nix` | GTK/Qt, fonts/icons, KDE Connect and Bluetooth media integration |
| `home/capture.nix` | Screenshot, recording, OCR and annotation dependencies |
| `home/displays.nix` | Display controls and laptop mirroring |
| `home/development/` | Editors, shared language/build tools, Git and GitHub CLI |
| `home/gaming.nix` | Steam/Millennium, game launchers and GameMode user daemon |
| `home/linux.nix` | Standalone Linux portals and graphics integration |
| `pkgs/` | Package fixes and scripts that genuinely require wrappers or migrations |

Import lists are explicit. Modules use ordinary Nix attributes, lists and
conditionals; there is no auto-import framework, custom option tree or overlay
layer. Add applications to their functional module and let native services
remain in `system/`. Hardware pins and state versions stay unchanged.

## Desktop coverage

- **Files:** Thunar with archive/removable-drive plugins, File Roller, modern
  7-Zip, ZIP utilities, GVfs/MTP/SSH mounts, trash and thumbnails. Standard home
  folders are created, and PDFs, images, archives and media have explicit handlers.
- **Work:** Zen, Discord, LibreOffice with English spellchecking, Xournal++,
  Papers, Simple Scan, a printer-settings UI, GIMP and Inkscape.
- **Media:** mpv and imv, English/Arabic OCR, Swappy, Screen Toolkit capture and
  recording, Bluetooth media keys, PipeWire and PulseAudio-client compatibility.
- **Development:** VSCodium, Neovim, language servers/runtimes, Make/CMake/Ninja,
  pkg-config, Git LFS, GitHub CLI, PlatformIO and project development shells.
- **Engineering/gaming:** Blender with laptop NVIDIA offload, FreeCAD, Logisim,
  Steam/Millennium and ProtonPlus; OrcaSlicer remains a user Flatpak.
- **Diagnostics:** btop, USB/PCI/storage tools, lsof/strace, sysstat, DNS lookup,
  nmap, iperf3, MTR, ethtool, curl/wget and rsync. Privileged operations still
  require the native host's permissions or sudo.

ProtonPlus is the one installed Proton-version manager. Swappy is the one
installed screenshot annotation editor. Rnote, protonup-ng and Satty are absent.
The two recording backends remain because Screen Toolkit actively supports
fallback between them. GNOME remains an alternative login session.

On NixOS, CUPS, IPP-over-USB, SANE/airscan and mDNS discovery provide print/scan
support. CUPS sharing stays disabled; mDNS discovery uses its standard UDP port.
MTR uses the native capability wrapper for unprivileged network diagnostics.
On standalone Linux, Home Manager installs the user tools only: the distribution
must supply audio, CUPS, Avahi, SANE/airscan, device rules, PAM and GPU drivers.
The existing bootstrap host-setup command previews a minimal native baseline;
it does not configure every optional desktop service.

## Validate and deploy

Run from the repository root:

```sh
(cd nixos && nix fmt)
nix flake check path:./nixos
nix build path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake path:./nixos#nixos
```

For standalone Linux:

```sh
bash nixos/bootstrap.sh --repo-dir "$PWD" --build-only
bash nixos/bootstrap.sh --repo-dir "$PWD" --activate
```

Review `profile.nix` and hardware before deploying to another machine. A
`path:` reference includes new files before Git tracks them. Existing mutable
GUI settings and migration backups retain their existing handling.

Update inputs deliberately and build before activating:

```sh
nix flake update nixpkgs home-manager --flake path:./nixos
nix build path:./nixos#nixosConfigurations.nixos.config.system.build.toplevel --no-link
```

The Noctalia updater also builds before asking to switch. Failed or declined
updates leave the lockfile for inspection. Independent Noctalia, Umbriel and
Millennium pins preserve binary-cache and runtime compatibility.

## Everyday commands

The same names work in Bash and Zsh on both backends:

| Command | Action |
| --- | --- |
| `cconf` | Enter the configuration directory |
| `cnf` | Open the module tree in `$EDITOR` |
| `neval` | Evaluate the flake without building checks |
| `ncheck` | Run the complete flake checks |
| `nbuild` | Build the selected NixOS/Home Manager profile without activation |
| `up` / `rebuild` | Build and switch through nh, with a package diff |
| `nupdate` | Refresh the lockfile only; inspect/build before switching |
| `nfmt` | Format the configuration tree without changing the shell's directory |

Eza supplies the standard listing aliases; `lt` limits the tree to two levels.
The formatter uses upstream `nixfmt-tree`, so `nix fmt` formats repository files
instead of waiting for standard input. Game launchers accept `--` before a
command. The combined NixOS updater validates the host name and uses a private
lock to prevent simultaneous updates from CLI and Noctalia.

## Resource policy and package fixes

Nix runs at most two local builds with four cores per build. Weekly collection
retains the existing 30-day generation policy; low-space collection starts below
1 GiB and aims for 5 GiB free without deleting live roots. Scheduled maintenance
runs at low CPU/I/O priority. Journals and Docker build cache remain bounded;
weekly SSD TRIM is already a NixOS default.

Application-specific insecure-package exceptions remain in
`package-policy.nix`, outside the system package set. WinBoat currently needs
its explicit Electron exception. The temporary Toolbox and version-specific
Zen download fixes are isolated in `pkgs/`; remove them when their locked
upstream packages no longer need them. Driver, suspend, monitor and printer
behavior still requires testing on actual hardware.
