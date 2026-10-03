{
  pkgs,
  inputs,
  config,
  ...
}:
let
  umbrielPortal =
    inputs.umbriel.inputs.xdg-desktop-portal-umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
  portalPackages = [ pkgs.xdg-desktop-portal ] ++ config.xdg.portal.extraPortals;
  # Export only the portal descriptor: native PAM owns the single keyring daemon.
  keyringPortal = pkgs.runCommand "gnome-keyring-portal-metadata" { } ''
    mkdir -p "$out/share/xdg-desktop-portal/portals"
    cp ${pkgs.gnome-keyring}/share/xdg-desktop-portal/portals/gnome-keyring.portal \
      "$out/share/xdg-desktop-portal/portals/"
  '';
in
{
  targets.genericLinux.enable = true;
  # Bootstrap's temporary flags must not be required for every later rebuild.
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  # Native kernel/GPU drivers, PAM and display-manager registration remain required.
  # genericLinux supplies the graphics environment; no nixGL wrapper is needed.
  xdg.portal = {
    enable = true;
    extraPortals = [
      umbrielPortal
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
      keyringPortal
    ];
    # One Nix portal stack serves this user's sessions, including native GNOME.
    # Select backends per desktop, without a common/default override.
    config = {
      gnome.default = [
        "gnome"
        "gtk"
      ];
      gnome."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      umbriel.default = [
        "umbriel"
        "gtk"
      ];
      umbriel."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
  };
  # Native login managers need system-level session registration; these user
  # units also make start-umbriel work from a login TTY.
  systemd.user.packages = portalPackages;
  dbus.packages = portalPackages;
}
