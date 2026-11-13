{ ... }:
{
  services.displayManager = {
    ly = {
      enable = true;
      # Only Wayland login sessions; XWayland remains enabled for applications.
      x11Support = false;
      settings.animation = "matrix";
    };
    defaultSession = "umbriel";
  };
}
