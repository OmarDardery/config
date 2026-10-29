# Configuration layout

The flake uses ordinary NixOS and Home Manager modules. There is no registration
framework or automatic directory discovery: every enabled module has an explicit
import.

| Location | Responsibility |
| --- | --- |
| `flake.nix` | Pinned inputs, system/home outputs, development shells and checks |
| `profile.nix` | Deployment identity and checkout path |
| `configuration.nix` | This host's hardware imports, optional bundles and state version |
| `hardware.nix` | Laptop-specific GPU, peripheral and storage policy |
| `hardware-configuration.nix` | Locally generated hardware, ignored by Git |
| `modules/default.nix` | Shared Home Manager composition and NixOS entry point |
| `home/` | Portable dotfiles and private NixOS editor dependencies |
| `system/` | Host services and desktop integration |
| `system/applications/` | Application packages grouped by purpose |
| `lib/`, `pkgs/` | Shared settings and package/helper implementations |
| `native/` | Debian/Fedora application installation |
| `tests/`, `checks.nix` | Behavioral and evaluation checks |

## Lean defaults and optional bundles

The desktop, browser, Kitty/Zsh/Yazi, both configured editors, office/media apps,
backup policy, Tailscale, capture tools and laptop hardware remain enabled.
Language toolchains are private editor dependencies or available through
`nix develop`; the system PATH no longer installs another global toolchain list.
This reduces global scope, but does not eliminate those dependencies from the
editor closure. JetBrains Toolbox is no longer installed alongside the two
configured editors.

Enable specialist bundles in `configuration.nix` as needed:

```nix
workstation = {
  gaming.enable = true;       # Steam, Millennium, GameMode, ProtonPlus
  engineering.enable = true;  # FreeCAD, Logisim, PlatformIO, webOS, OrcaSlicer
  containers.enable = true;   # Docker socket and WinBoat
  printing.enable = true;     # Printers, scanners and network discovery
};
```

All four default to false. Each bundle owns the related packages and services;
Docker group membership and WinBoat's Electron exception exist only with the
container bundle. Disabling a bundle removes declarative packages and services;
it does not erase application data, Docker volumes or backups. Flatpak retains
`uninstallUnmanaged = false`, so existing Flatpaks are not forcibly removed.
Use `nix develop path:./nixos#general`, `#embedded`, `#python` or `#rustup`
from the repository root for project tools.

## Ownership and compatibility

NixOS owns application/service installation, Home Manager owns dotfiles and
Nix-packaged editors. Standalone Home Manager owns configuration only; native
package managers and editor installers own applications. Both standalone selectors
(`oad` and `oad-desktop` with the default identity) retain the same dotfile scope.
`lib.deployment` and the NixOS host selector are unchanged.

Desktop setup runs through the native graphical-session unit, never during
Home Manager activation. Existing caches and independent Noctalia/Umbriel input
pins are preserved for binary compatibility. Removing the top-level flake-parts
input does not update unrelated lock-file pins.

Use `path:` flake references so the local hardware file participates in builds.
Never deploy the CI hardware fixture. State versions, NVIDIA/kernel policy,
storage mounts and backup policy are unchanged.

## Inspiration and verification

The direct output/module layout follows the small, explicit structure of
[Misterio77's starter configuration](https://github.com/Misterio77/nix-starter-configs/tree/main/standard).
Separating core dependencies from feature-owned extras follows
[hlissner's dotfiles](https://github.com/hlissner/dotfiles).
Only structural ideas are borrowed; their hardware and package choices are not.

Run `bash nixos/tests/ci.sh` from the repository root. It evaluates with disposable
hardware, checks portable profiles and the desktop, and exercises both minimal
and fully enabled optional bundles through `checks.features`. Live graphics,
printing, Docker and suspend behavior still need testing on the actual laptop.
