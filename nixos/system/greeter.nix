{ ... }:
{
  services.displayManager = {
    ly = {
      enable = true;
      # Umbriel is Wayland; XWayland applications still work inside the session.
      x11Support = false;
      settings.animation = "matrix";
    };
    defaultSession = "umbriel";
  };
}
