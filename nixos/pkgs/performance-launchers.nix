{
  pkgs,
  isNixOS,
  isLaptop,
  powerProfiles ? pkgs.power-profiles-daemon,
  gameMode ? pkgs.gamemode,
  offload ? import ./nvidia-offload.nix { inherit pkgs; },
}:
let
  inherit (pkgs) lib;
  performanceRun = pkgs.writeShellApplication {
    name = "performance-run";
    text = ''
      if [[ $# == 0 ]]; then
        printf '%s\n' 'Usage: performance-run COMMAND [ARG...]' >&2
        exit 2
      fi
      # HoldProfile releases automatically when this client exits. No global
      # profile set/reset, so concurrent holds and manual GUI choices still work.
      exec ${lib.getExe' powerProfiles "powerprofilesctl"} launch --profile performance -- "$@"
    '';
  };
  gameRun = pkgs.writeShellApplication {
    name = "game-run";
    text = ''
      offload_game=${lib.boolToString isLaptop}
      if [[ "''${1:-}" == --integrated ]]; then
        offload_game=false
        shift
      fi
      if [[ $# == 0 ]]; then
        printf '%s\n' 'Usage: game-run [--integrated] COMMAND [ARG...]' >&2
        exit 2
      fi
      command=( ${lib.getExe' gameMode "gamemoderun"} "$@" )
      if [[ "$offload_game" == true ]]; then
        ${if isLaptop then ''command=( ${lib.getExe offload} "''${command[@]}" )'' else ":"}
      fi
      ${
        if isNixOS then
          ''
            exec ${lib.getExe performanceRun} "''${command[@]}"
          ''
        else
          ''
            exec "''${command[@]}"
          ''
      }
    '';
  };
in
{
  inherit performanceRun gameRun;
}
