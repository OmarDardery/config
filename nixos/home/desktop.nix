{
  pkgs,
  lib,
  isLaptop,
  ...
}:
{
  services.kdeconnect.enable = true;
  services.mpris-proxy.enable = true;
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  xfconf = {
    enable = true;
    settings.xsettings."Net/ThemeName" = "Adwaita-dark";
  };
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraCss = ''@import url("noctalia.css");'';
    gtk4.extraCss = ''@import url("noctalia.css");'';
  };
  xresources.properties."Xft.dpi" = lib.mkIf isLaptop (
    toString (96 * (import ../lib/display.nix).laptopScale)
  );
}
