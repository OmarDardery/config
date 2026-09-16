{ ... }:
{
  imports = [
    ./development
    ./3d.nix
    ./apps.nix
    ./shell.nix
    ./nix-tools.nix
    ./desktop.nix
    ./noctalia.nix
    ./host.nix
    # ./optional/brave-origin.nix
  ];

  home.username = "oad";
  home.homeDirectory = "/home/oad";

  home.stateVersion = "26.05"; # Please read the comment before changing.

  programs.home-manager.enable = true;
}
