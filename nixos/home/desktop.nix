{ pkgs, lib, ... }:
{
  services.kdeconnect.enable = true;
  systemd.user.services.kdeconnect = {
    Unit.BindsTo = [ "graphical-session.target" ];
    Service = {
      Type = "dbus";
      BusName = "org.kde.kdeconnect";
    };
  };
  # GNOME otherwise starts a second daemon through the package's XDG autostart.
  xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE Connect
    Hidden=true
  '';
  # D-Bus activation must use the same session-bound service, not fork a daemon.
  xdg.dataFile."dbus-1/services/org.kde.kdeconnect.service".text = ''
    [D-BUS Service]
    Name=org.kde.kdeconnect
    Exec=${pkgs.coreutils}/bin/false
    SystemdService=kdeconnect.service
  '';

  # Bridge Bluetooth media buttons to desktop media players.
  services.mpris-proxy.enable = true;
  systemd.user.services.mpris-proxy = {
    Unit = {
      BindsTo = lib.mkForce [ "graphical-session.target" ];
      After = lib.mkForce [ "graphical-session.target" ];
      ConditionPathExists = "/sys/class/bluetooth";
    };
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
    Service.Restart = "on-failure";
    Service.RestartSec = "5s";
  };

  # Required for pointerCursor.gtk to deploy the cursor settings.
  gtk.enable = true;
  gtk.gtk3.extraCss = ''@import url("noctalia.css");'';
  gtk.gtk4.extraCss = ''@import url("noctalia.css");'';
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # Single source of truth for the cursor. This sets XCURSOR_THEME/XCURSOR_SIZE
  # for the session, writes the GTK settings, and populates ~/.icons, replacing
  # three separate declarations that had drifted apart.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

  # Fonts in home.packages are invisible to fontconfig on NixOS unless this is
  # on: the per-user directory under /etc/profiles is not a path fontconfig
  # searches by default. Without it, kitty's JetBrainsMono falls back to DejaVu.
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    adwaita-icon-theme
    adw-gtk3
    glib
    dconf
    pavucontrol
    brightnessctl
    playerctl
  ];
}
