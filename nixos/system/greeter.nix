{ ... }:
{
  services.displayManager = {
    ly = {
      enable = true;
      # XFCE needs X11; Umbriel remains available as a Wayland session.
      x11Support = true;
      settings.animation = "matrix";
    };
    defaultSession = "umbriel";
  };
}
