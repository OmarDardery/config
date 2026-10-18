{ profile, ... }:
{
  imports = [
    ./development
    ./apps.nix
    ./files.nix
    ./engineering.nix
    ./kitty.nix
    ./terminal.nix
    ./capture.nix
    ./displays.nix
    ./gaming.nix
    ./shell.nix
    ./nix-tools.nix
    ./desktop.nix
    ./hardware-user.nix
    ./noctalia.nix
    ./umbriel.nix
    ./flatpak.nix
  ];

  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;

  home.stateVersion = "26.05"; # Preserve the installation's stateful defaults.

  programs.home-manager.enable = true;
}
