# GNOME, as a fallback session next to Umbriel. SDDM already runs and already lists
# every session it finds — see display-manager.nix — so this is the whole thing.
{ pkgs, ... }:
{
  # Unlike the plasma6 module, this one does not set
  # services.displayManager.defaultSession and does not enable GDM, so Umbriel stays
  # the default and the pixie SDDM theme is untouched. Nothing to counter here.
  #
  # GNOME 50 is Wayland-only: gnome-session ships share/wayland-sessions/gnome.desktop
  # and no xsessions entry at all. There is no GNOME-on-X11 to fall back to.
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;

  # The fallback session does not need a screen reader. GNOME enables Orca and
  # speech-dispatcher by default; the latter pulls roughly 645 MiB of MBROLA
  # voices into the system closure.
  environment.gnome.excludePackages = with pkgs; [
    orca
    # User-facing core-shell tools are also installed/registered by HM.
    gnome-color-manager
    gnome-control-center
    gnome-tour
    gnome-user-docs
    gnome-backgrounds
    glycin-thumbnailer
    gst-thumbnailers
  ];
  services.speechd.enable = false;

  # The complete core-apps set, including its four program/service modules,
  # lives in home/apps.nix with user D-Bus, units and schema registration.
  # Keep core-shell/core-os-services here: session registration, PAM/keyring,
  # settings daemons, portals and system-bus services are native infrastructure.
}
