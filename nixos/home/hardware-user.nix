{
  pkgs,
  lib,
  isLaptop,
  config,
  ...
}:
let
  scale = (import ../lib/display.nix).laptopScale;
  width = builtins.ceil (2560 / scale);
  height = builtins.ceil (1600 / scale);
  defaults = builtins.fromJSON (builtins.readFile ../assets/tablet-settings.json);
  profile = builtins.head defaults.Profiles;
  tabletSettings = pkgs.writeText "tablet-settings.json" (
    builtins.toJSON (
      defaults // {
        Profiles = [
          (profile // {
            AbsoluteModeSettings = profile.AbsoluteModeSettings // {
              Display = {
                Width = width;
                Height = height;
                X = width / 2.0;
                Y = height / 2.0;
                Rotation = 0;
              };
            };
          })
        ];
      }
    )
  );
in
lib.mkIf isLaptop {
  # Seed the laptop mapping in logical pixels. Migrate known old defaults while
  # preserving custom areas, pressure settings and express-key bindings.
  home.activation.openTabletDriverBindings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${../pkgs}/migrate-desktop.py tablet \
      ${lib.escapeShellArg "${config.xdg.configHome}/OpenTabletDriver/settings.json"} ${tabletSettings}
  '';
  home.activation.xournalppStylusButtons = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${pkgs.procps}/bin/pgrep -u "$UID" -f '(^|/)\.?xournalpp(-wrapped)?([[:space:]]|$)' >/dev/null; then
      echo "Xournal++ is open; close it before activating stylus-button defaults."
    else
      run ${pkgs.python3}/bin/python3 ${../pkgs}/migrate-desktop.py xournalpp-buttons \
        ${lib.escapeShellArg "${config.xdg.configHome}/xournalpp/settings.xml"}
    fi
  '';
}
