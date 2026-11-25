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
        # macOS-style login: large clock at the top, heavily frosted
        # wallpaper and a bare password field, without logo or scheme picker.
        appearance = {
          hide_logo = true;
          scheme_selector_position = "hidden";
          power_buttons_position = "bottom-right";
          password_style = "default";
          font_family = "Inter";
          wallpaper = {
            # Dark fallback until the first appearance sync has installed
            # the desktop wallpaper.
            blur = 0.75;
            tint = 0.15;
            fill_color = "#11151e";
          };
        };
        clock = {
          enabled = true;
          position = "top-center";
          time_format = "{:%H:%M}";
          date_format = "%A %-d %B";
          time_font_size = 96;
          date_font_size = 18;
        };
        # Same layouts and switch chord as the desktop.
        keyboard = {
          layout = "us,ara";
          options = "grp:alt_shift_toggle";
        };
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
