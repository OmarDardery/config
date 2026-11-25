# Laptop battery policy: power profile and panel refresh follow AC, battery and games.
{
  config,
  lib,
  pkgs,
  isLaptop,
  ...
}:
let
  power-policy = pkgs.writeShellApplication {
    name = "power-policy";
    runtimeInputs = [
      config.programs.umbriel.package
      config.services.power-profiles-daemon.package
      pkgs.coreutils
      pkgs.jq
      pkgs.systemd
      pkgs.wlr-randr
    ];
    text = builtins.readFile ../scripts/power-policy.sh;
  };
in
lib.mkIf isLaptop {
  environment.systemPackages = [ power-policy ];

  # Runs inside the Umbriel session, which exports WAYLAND_DISPLAY to systemd.
  systemd.user.services.power-policy = {
    description = "Switch power profile and refresh rate with AC, battery and games";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe power-policy} watch";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Games launched with `gamemoderun` get the performance profile and 165 Hz.
  programs.gamemode.settings.custom = lib.mkIf config.workstation.gaming.enable {
    start = "${lib.getExe power-policy} game-start";
    end = "${lib.getExe power-policy} game-end";
  };
}
