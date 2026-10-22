{
  pkgs,
  inputs,
  profile,
  ...
}:
{
  programs.steam = {
    enable = true;
    package =
      (import ../pkgs/steam.nix {
        inherit pkgs;
        millenniumInput = inputs.millennium;
        colorsFile = "${profile.homeDirectory}/.local/state/noctalia/theme/steam.css";
      }).steam;
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
