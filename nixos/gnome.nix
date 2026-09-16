# GNOME, as a second session next to niri. SDDM already runs and already lists
# every session it finds — see display-manager.nix — so this is the whole thing.
{ pkgs, ... }:
{
  # Unlike the plasma6 module, this one does not set
  # services.displayManager.defaultSession and does not enable GDM, so niri stays
  # the default and the pixie SDDM theme is untouched. Nothing to counter here.
  #
  # GNOME 50 is Wayland-only: gnome-session ships share/wayland-sessions/gnome.desktop
  # and no xsessions entry at all. There is no GNOME-on-X11 to fall back to.
  services.desktopManager.gnome.enable = true;

  # The fallback session does not need a screen reader. GNOME enables Orca and
  # speech-dispatcher by default; the latter pulls roughly 645 MiB of MBROLA
  # voices into the system closure.
  environment.gnome.excludePackages = [ pkgs.orca ];
  services.speechd.enable = false;

  # services.gnome.core-apps defaults on, which is deliberate — a fallback
  # session you cannot open a file or a text editor in is not much of a fallback.
  # That is Nautilus, Loupe, Papers, Text Editor, System Monitor, Disks, Music,
  # Weather, Maps and friends. Games and developer tools stay off; both default
  # to off already.
  #
  # `environment.gnome.excludePackages` is the switch if that turns out to be too
  # much, and unlike KDE's equivalent it actually works: this module filters its
  # whole app list through it, whereas environment.plasma6.excludePackages only
  # filters an "optional" sub-list and cannot touch the rest.

  # ── What this does to the niri session too ─────────────────────────────
  # Three of the module's settings are environment.sessionVariables or global
  # programs, so they apply to every session, not just GNOME:
  #
  #   * XDG_DATA_DIRS gains GNOME's mimeapps list. This can change which app
  #     opens a PDF, an image or a video under niri as well. It is the one most
  #     likely to surprise you — check with `xdg-mime query default` if a file
  #     starts opening in the wrong thing.
  #   * NAUTILUS_4_EXTENSION_DIR is set. Harmless; nautilus is already installed.
  #   * programs.dconf.enable is turned on. Harmless, and mildly useful for GTK
  #     apps under niri.
  #
  # nautilus and papers are also in home/apps.nix. That duplication is on
  # purpose: home/ has to stand on its own on a machine without GNOME, so do not
  # "clean up" the home entries by pointing at these. The home profile wins on
  # PATH either way.
}
