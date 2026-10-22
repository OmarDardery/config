{ profile, ... }:
{
  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;
  home.stateVersion = "26.05";
  programs.home-manager.enable = false;
  programs.man.enable = false;
  manual.manpages.enable = false;
  xdg.mime.enable = false;
  fonts.fontconfig.enable = false;
}
