{ profile, ... }:
{
  imports = [
    ./development
    ./apps.nix
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

  home.stateVersion = "26.05"; # Please read the comment before changing.

  programs.home-manager.enable = true;
}
