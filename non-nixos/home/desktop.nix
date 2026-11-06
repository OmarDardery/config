{ pkgs, ... }:
let
  shared = import ../packages.nix { inherit pkgs; };
in
{
  home.packages =
    shared.desktop
    ++ shared.fonts
    ++ (with pkgs; [
      kitty
      starship
      zsh
      thunar
      keepassxc
      xclip
      pavucontrol
      btop
      zoxide
      direnv
      unzip
      _7zz
    ]);
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    TERMINAL = "kitty";
    SAL_USE_VCLPLUGIN = "gtk3";
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "application/pdf" = [ "org.gnome.Papers.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "text/plain" = [ "codium.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
    };
  };
}
