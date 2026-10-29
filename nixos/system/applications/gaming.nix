{
  config,
  pkgs,
  profile,
  inputs,
  lib,
  isNixOS,
  isLaptop,
  ...
}:
let
  launchers = import ../../pkgs/performance-launchers.nix { inherit pkgs isNixOS isLaptop; };
  steamPackages = import ../../pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    colorsFile = "${profile.homeDirectory}/.local/state/noctalia/theme/steam.css";
  };

in
lib.mkIf config.workstation.gaming.enable {
  environment.systemPackages = [
    steamPackages.setup
    steamPackages.millennium
    launchers.gameRun
  ];
  environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
}
