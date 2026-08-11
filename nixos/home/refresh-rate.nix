# Keep the panel's refresh rate in step with the power profile.
{ pkgs, ... }:
let
  niri-refresh-rate = pkgs.writeShellApplication {
    name = "niri-refresh-rate";

    # niri is deliberately absent here: `niri msg` has to be the same build as
    # the running compositor, and that one is already on the session PATH.
    # Adding pkgs.niri would pull in a second copy that could disagree over IPC.
    # glib is here for gdbus, which is what watches the bus.
    runtimeInputs = with pkgs; [ glib jq power-profiles-daemon ];

    text = builtins.readFile ./scripts/niri-refresh-rate.sh;
  };
in
{
  # Also a normal command, so it can be run by hand while debugging.
  home.packages = [ niri-refresh-rate ];

  # graphical-session.target rather than niri.service, so this still starts if
  # the compositor is ever swapped. NIRI_SOCKET is already in the systemd user
  # environment, which is how `niri msg` finds the compositor from here.
  systemd.user.services.niri-refresh-rate = {
    Unit = {
      Description = "Match the panel refresh rate to the active power profile";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${niri-refresh-rate}/bin/niri-refresh-rate";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
