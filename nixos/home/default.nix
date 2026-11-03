{
  inputs,
  profile,
  ...
}:
{
  imports = [
    ./yazi.nix
    ./shell.nix
    ./git.nix
    ./nix-tools.nix
    ./editors
    inputs.noctalia.homeModules.default
    inputs.umbriel.homeModules.default
    ./desktop.nix
    ./files.nix
    ./noctalia.nix
    ./umbriel.nix
    ./kitty.nix
  ];
  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;
  home.stateVersion = profile.homeStateVersion;
  programs.home-manager.enable = false;
  programs.man.enable = false;
  manual.manpages.enable = false;
  xdg.mime.enable = false;
}
