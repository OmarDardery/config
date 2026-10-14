{
  pkgs,
  config,
  inputs,
  lib,
  isNixOS,
  isLaptop,
  osConfig ? null,
  ...
}:
let
  launchers = import ../pkgs/performance-launchers.nix { inherit pkgs isNixOS isLaptop; };
  steamPackages = import ../pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    colorsFile = "${config.xdg.stateHome}/noctalia/theme/steam.css";
  };
  # NixOS's Steam module injected these into the FHS runtime. Keep that driver
  # and font integration even though Home Manager now owns the application.
  steam =
    if isNixOS then
      steamPackages.steam.override (previous: {
        extraLibraries =
          runtimePkgs:
          (previous.extraLibraries runtimePkgs)
          ++ (
            with osConfig.hardware.graphics;
            if runtimePkgs.stdenv.hostPlatform.is64bit then
              [ package ] ++ extraPackages
            else
              [ package32 ] ++ extraPackages32
          );
        extraPkgs =
          runtimePkgs:
          lib.optionals (previous ? extraPkgs) (previous.extraPkgs runtimePkgs)
          ++ builtins.filter lib.types.package.check osConfig.fonts.packages;
      })
    else
      steamPackages.steam;
in
{
  home.packages = [
    steam
    steam.run
    steamPackages.setup
    steamPackages.millennium
    pkgs.gamemode
    launchers.gameRun
  ]
  ++ lib.optionals isNixOS [ launchers.performanceRun ];
  home.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
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
