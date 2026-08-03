{ pkgs, inputs, ... }:

{
  home.username = "oad";
  home.homeDirectory = "/home/oad";

  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = with pkgs; [];

  programs.home-manager.enable = true;
  

  #niri
  xdg.configFile."niri".source = ./modules/niri;
  #kitty
  xdg.configFile."kitty".source = ./modules/kitty;

 
  programs.git = {
    enable = true;
    settings.user.name = "OmarDardery";
    settings.user.email = "oadardery@gmail.com";
  };
}
