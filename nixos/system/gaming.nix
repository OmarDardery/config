{
  config,
  lib,
  pkgs,
  inputs,
  profile,
  isLaptop,
  isNixOS,
  ...
}:
let
  steam = import ../pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    desktopScale = if isLaptop then (import ../lib/display.nix).laptopScale else null;
    colorsFile = "${profile.homeDirectory}/.local/state/noctalia/theme/steam.css";
  };
  launchers = import ../pkgs/performance-launchers.nix { inherit pkgs isNixOS isLaptop; };
in
lib.mkIf config.workstation.gaming.enable {
  environment.systemPackages = [ steam.setup steam.millennium launchers.gameRun ];
  environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  services.flatpak.packages = [ "com.vysp3r.ProtonPlus" ];

  programs.steam = {
    enable = true;
    package = steam.steam;
    remotePlay.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;
  };
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        # amd-pstate-epp uses EPP to boost; powersave permits PPD's EPP changes.
        # game-run holds the performance profile instead of racing PPD with
        # governor changes that could outlive the game.
        desiredgov = "powersave";
        igpu_desiredgov = "powersave";
        softrealtime = "off";
      };
      cpu = {
        pin_cores = "no";
        park_cores = "no";
      };
    };
  };
  users.users.${profile.username}.extraGroups = [ "gamemode" ];
}
