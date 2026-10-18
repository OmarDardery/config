{
  pkgs,
  config,
  inputs,
  lib,
  isNixOS,
  isLaptop,
  ...
}:
let
  launchers = import ../pkgs/performance-launchers.nix { inherit pkgs isNixOS isLaptop; };
  steamPackages = import ../pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    colorsFile = "${config.xdg.stateHome}/noctalia/theme/steam.css";
  };

in
{
  home.packages = [
    steamPackages.setup
    steamPackages.millennium
    launchers.gameRun
  ]
  ++ lib.optionals isNixOS [ launchers.performanceRun ];
  home.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
}
