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
    # Claude Code CLI (`claude`); the package disables its self-updater, so
    # updates arrive with `up`.
    pkgs.claude-code
  ];

  services.mpris-proxy.enable = true;
  services.kdeconnect = {
    enable = true;
    # Tray icon in the menu bar for pairing, sharing and phone actions.
    indicator = true;
  };
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
    # Inter is the closest freely licensed match for the macOS system font.
    font = {
      name = "Inter";
      size = 11;
    };
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
