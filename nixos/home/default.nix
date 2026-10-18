{ profile, ... }:
{
  imports = [
    ./development
    ./terminal.nix
    ./workspace.nix
    ./office.nix
    ./shell.nix
    ./nix-tools.nix
  ];

  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;

  home.stateVersion = "26.05"; # Preserve the installation's stateful defaults.

  programs.home-manager.enable = true;
}
