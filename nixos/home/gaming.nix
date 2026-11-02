{
  config,
  inputs,
  lib,
  pkgs,
  profile,
  isLaptop,
  osConfig,
  ...
}:
let
  native = import ../pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    desktopScale = if isLaptop then (import ../lib/display.nix).laptopScale else null;
    colorsFile = "${profile.homeDirectory}/.local/state/noctalia/theme/steam.css";
  };
in
lib.mkIf osConfig.workstation.gaming.enable {
  home.packages = [
    osConfig.programs.steam.package
    native.setup
    native.millennium
  ];
  home.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${config.home.homeDirectory}/.steam/root/compatibilitytools.d";
}
