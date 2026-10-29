{ inputs, profile, ... }:
{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];
  services.displayManager.noctalia-greeter = {
    enable = true;
    passwordless-sync-users = [ profile.username ];
    settings = {
      session.default = "umbriel";
      user.default = profile.username;
      keyboard = {
        layout = "us,ara";
        options = "grp:alt_shift_toggle";
      };
    };
  };
  services.displayManager.defaultSession = "umbriel";
}
