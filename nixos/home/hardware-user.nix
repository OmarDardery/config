{
  pkgs,
  lib,
  isLaptop,
  config,
  ...
}:
lib.mkIf isLaptop {
  # Keep GUI settings writable. Seed the profile on a fresh installation and
  # reapply only the Deco mini7 auxiliary bindings on subsequent activations.
  home.activation.openTabletDriverBindings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${../pkgs}/migrate-desktop.py tablet \
      ${lib.escapeShellArg "${config.xdg.configHome}/OpenTabletDriver/settings.json"} ${../assets/tablet-settings.json}
  '';

}
