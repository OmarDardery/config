{
  inputs,
  profile,
  features,
  lib,
  ...
}:
{
  imports = [
    ./yazi.nix
    ./shell.nix
    ./git.nix
    ./nix-tools.nix
  ]
  ++ lib.optionals features.development [
    ./editors
    ./development.nix
    ./graphics.nix
  ]
  ++ lib.optionals features.gaming [ ./gaming.nix ]
  ++ lib.optionals features.desktop [
    inputs.noctalia.homeModules.default
    inputs.umbriel.homeModules.default
    ./desktop.nix
    ./files.nix
    ./noctalia.nix
    ./umbriel.nix
    ./kitty.nix
    ./office.nix
  ];
  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;
  home.stateVersion = "26.05";
  programs.home-manager.enable = false;
  programs.man.enable = false;
  manual.manpages.enable = false;
  xdg.mime.enable = false;
}
