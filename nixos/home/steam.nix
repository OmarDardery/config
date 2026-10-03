{
  config,
  pkgs,
  lib,
  inputs,
  isNixOS,
  osConfig ? null,
  ...
}:
let
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
  # No activation hooks, runtime configuration replacement, or automatic setup.
  # Both deployment backends install Steam exclusively through Home Manager.
  home.packages = [
    steam
    steam.run
    steamPackages.setup
    steamPackages.millennium
  ];
  home.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
}
