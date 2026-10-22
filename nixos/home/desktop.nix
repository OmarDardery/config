{ isNixOS, ... }:
let
  cursor = if isNixOS then "Bibata-Modern-Classic" else "Adwaita";
in
{
  xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".enable = isNixOS;
  xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE Connect
    Hidden=true
  '';
  xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".enable = isNixOS;
  xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".text = ''
    [D-BUS Service]
    Name=org.kde.kdeconnect
    Exec=${if isNixOS then "/run/current-system/sw/bin/false" else "/usr/bin/false"}
    SystemdService=kdeconnect.service
  '';
  xdg.configFile."gtk-3.0/gtk.css".text = ''@import url("noctalia.css");'';
  xdg.configFile."gtk-4.0/gtk.css".text = ''@import url("noctalia.css");'';
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-cursor-theme-name=${cursor}
    gtk-cursor-theme-size=24
    gtk-icon-theme-name=Adwaita
  '';
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-cursor-theme-name=${cursor}
    gtk-cursor-theme-size=24
    gtk-icon-theme-name=Adwaita
  '';
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=${cursor}
  '';
}
