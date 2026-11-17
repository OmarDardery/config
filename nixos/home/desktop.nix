{
  pkgs,
  inputs,
  ...
}:
{
  # Install WinBoat per user, without pulling in the obsolete Electron 40
  # package from the system's stable Nixpkgs.
  home.packages = [
    inputs.noctalia.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.winboat
  ];

  services.mpris-proxy.enable = true;
  services.kdeconnect.enable = true;
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = false;
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
}
