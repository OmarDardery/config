{
  lib,
  isLaptop,
  ...
}:
let
  cursor = "Bibata-Modern-Classic";
  display = import ../lib/display.nix;
in
{
  services.kdeconnect.enable = true;
  services.mpris-proxy.enable = true;
  xdg.configFile = {
    # Merge our font DPI without replacing unrelated X resources.
    "X11/Xresources" = {
      enable = isLaptop;
      text = "Xft.dpi: ${toString (96 * display.laptopScale)}\n";
    };
  }
  // lib.genAttrs [ "gtk-3.0/gtk.css" "gtk-4.0/gtk.css" ] (_: {
    text = ''@import url("noctalia.css");'';
  })
  // lib.genAttrs [ "gtk-3.0/settings.ini" "gtk-4.0/settings.ini" ] (_: {
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
