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
