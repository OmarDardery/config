{
  pkgs,
  lib,
  isNixOS,
  osConfig ? null,
  ...
}:
{
  home.packages = [ pkgs.gamemode ];
  dbus.packages = [ pkgs.gamemode ];

  # Match the package's native user unit, including persistent and D-Bus
  # activation. HM's generated unit selects the privileged NixOS wrapper.
  systemd.user.services.gamemoded = {
    Unit.Description = "gamemoded";
    Service = {
      Type = "dbus";
      BusName = "com.feralinteractive.GameMode";
      NotifyAccess = "main";
      ExecStart =
        if isNixOS then "${osConfig.security.wrapperDir}/gamemoded" else "${pkgs.gamemode}/bin/gamemoded";
      # Exclude all other privileged wrappers, as in the upstream NixOS module.
      Environment = lib.mkIf isNixOS [
        "PATH=${
          pkgs.linkFarm "pkexec" [
            {
              name = "pkexec";
              path = "${osConfig.security.wrapperDir}/pkexec";
            }
          ]
        }"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Standalone Nix runs the daemon unprivileged. CPU/GPU helper operations and
  # renicing need manual native-host setup: capabilities, pkexec and polkit
  # policy matching this package's absolute helper paths. A distro GameMode
  # policy alone does not authorize the Nix-store helpers.
}
