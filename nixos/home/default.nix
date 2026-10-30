{ inputs, profile, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
    inputs.umbriel.homeModules.default
    ./editors
    ./desktop.nix
    ./files.nix
    ./noctalia.nix
    ./umbriel.nix
    ./yazi.nix
    ./office.nix
    ./shell.nix
    ./git.nix
    ./kitty.nix
    ./nix-tools.nix
  ];

  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;
  home.stateVersion = "26.05";
  programs.home-manager.enable = false;
  programs.man.enable = false;
  manual.manpages.enable = false;
  xdg.mime.enable = false;
  fonts.fontconfig.enable = false;
}
