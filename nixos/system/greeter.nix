{ ... }:
{
  services.displayManager = {
    ly = {
      enable = true;
      # Only Wayland login sessions.
      x11Support = false;
      settings.animation = "matrix";
    };
    defaultSession = "umbriel";
  };
}
