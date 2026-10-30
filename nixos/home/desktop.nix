{
  lib,
  isNixOS,
  isLaptop,
  ...
}:
let
  cursor = if isNixOS then "Bibata-Modern-Classic" else "Adwaita";
  display = import ../lib/display.nix;
in
{
  xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".enable = isNixOS;
  xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".text = ''
    [D-BUS Service]
    Name=org.kde.kdeconnect
    Exec=${if isNixOS then "/run/current-system/sw/bin/false" else "/usr/bin/false"}
    SystemdService=kdeconnect.service
  '';
  xdg.configFile = {
    # Merge our font DPI without replacing unrelated X resources.
    "X11/Xresources" = {
      enable = isLaptop;
      text = "Xft.dpi: ${toString (96 * display.laptopScale)}\n";
    };
    "autostart/org.kde.kdeconnect.daemon.desktop".enable = isNixOS;
    "autostart/org.kde.kdeconnect.daemon.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=KDE Connect
      Hidden=true
    '';
  } // lib.genAttrs [ "gtk-3.0/gtk.css" "gtk-4.0/gtk.css" ] (_: {
    text = ''@import url("noctalia.css");'';
  }) // lib.genAttrs [ "gtk-3.0/settings.ini" "gtk-4.0/settings.ini" ] (_: {
    text = ''
      [Settings]
      gtk-cursor-theme-name=${cursor}
      gtk-cursor-theme-size=24
      gtk-icon-theme-name=Adwaita
    '';
  });
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=${cursor}
  '';
}
