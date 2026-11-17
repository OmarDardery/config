# A single native Wayland login manager, using the upstream Noctalia Greeter module.
{ inputs, pkgs, profile, ... }:
{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  services.displayManager = {
    defaultSession = "umbriel";
    noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "umbriel";
        user.default = profile.username;
        # Do not pin a palette or wallpaper: Noctalia's Synced colors and
        # chosen wallpaper should follow the current desktop appearance.
        appearance = {
          wallpaper = {
            # Gentle frosted-glass backdrop, with a dark fallback until
            # the first appearance sync has installed the desktop wallpaper.
            blur = 0.48;
            tint = 0.22;
            fill_color = "#11151e";
          };
        };
        clock = {
          enabled = true;
          position = "above-panel";
          time_format = "{:%H:%M}";
          date_format = "%A, %d %B";
          time_font_size = 52;
          date_font_size = 15;
        };
        keyboard.layout = "us";
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 24;
          path = pkgs.bibata-cursors;
        };
      };
      # Only the narrowly scoped appearance-sync action is passwordless.
      passwordless-sync-users = [ profile.username ];
    };
  };

  # greetd authenticates the session and unlocks the GNOME keyring.
  security.pam.services.greetd.enableGnomeKeyring = true;
}
