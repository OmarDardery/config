# User preferences and applications for the system-integrated NixOS desktop.
{ ... }:
{
  imports = [
    ./default.nix
    ./apps.nix
    ./files.nix
    ./engineering.nix
    ./kitty.nix
    ./capture.nix
    ./displays.nix
    ./gaming.nix
    ./desktop.nix
    ./hardware-user.nix
    ./noctalia.nix
    ./umbriel.nix
    ./flatpak.nix
    ./development/vscode.nix
  ];
}
