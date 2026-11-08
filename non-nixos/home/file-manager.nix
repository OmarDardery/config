{ pkgs, ... }:
{
  home.packages = [ pkgs.thunar ];
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "thunar.desktop" ];
  };
  xdg.configFile."xfce4/helpers.rc".text = "FileManager=Thunar\\n";
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.FileManager1
    Exec=${pkgs.thunar}/bin/Thunar --gapplication-service
  '';
}
