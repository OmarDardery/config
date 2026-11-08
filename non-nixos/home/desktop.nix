{ pkgs, ... }:
let
  shared = import ../packages.nix { inherit pkgs; };
in
{
  home.packages =
    shared.desktop
    ++ shared.fonts
    ++ (with pkgs; [
      thunar
      keepassxc
      xclip
      pavucontrol
      btop
      unzip
      _7zz
    ]);
  # Prefer Thunar for both directory associations and "Show in folder" requests.
  xdg.configFile."xfce4/helpers.rc".text = "FileManager=Thunar\n";
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.FileManager1
    Exec=${pkgs.thunar}/bin/Thunar --gapplication-service
  '';
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    SAL_USE_VCLPLUGIN = "gtk3";
  };
  xdg.mimeApps = {
    enable = true;
    associations = {
      added."inode/directory" = [ "thunar.desktop" ];
      removed."inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
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
