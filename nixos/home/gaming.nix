{
  config,
  inputs,
  lib,
  pkgs,
  profile,
  isNixOS,
  isLaptop,
  osConfig ? { },
  ...
}:
let
  enabled = !isNixOS || (osConfig.workstation.gaming.enable or false);
  native = import ../pkgs/steam.nix {
    inherit pkgs;
    millenniumInput = inputs.millennium;
    desktopScale = if isLaptop then (import ../lib/display.nix).laptopScale else null;
    colorsFile = "${profile.homeDirectory}/.local/state/noctalia/theme/steam.css";
  };
  flatpakSteam = pkgs.writeShellScriptBin "steam" ''
    exec ${pkgs.flatpak}/bin/flatpak run --user com.valvesoftware.Steam "$@"
  '';
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  home.packages = lib.optionals enabled (
    if isNixOS then
      [
        osConfig.programs.steam.package
        native.setup
        native.millennium
      ]
    else
      [
        pkgs.flatpak
        flatpakSteam
      ]
  );
  home.sessionVariables = lib.optionalAttrs (isNixOS && enabled) {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${config.home.homeDirectory}/.steam/root/compatibilitytools.d";
  };
  services.flatpak = {
    enable = !isNixOS;
    packages = [ "com.valvesoftware.Steam" ];
    uninstallUnmanaged = false;
    uninstallUnused = false;
    update.auto.enable = true;
  };
  # Make initial installation synchronous: failed downloads must fail the apply.
  home.activation.flatpak-managed-install = lib.mkIf (!isNixOS) (
    lib.mkForce (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${lib.escapeShellArgs (map toString config.systemd.user.services.flatpak-managed-install.Service.ExecStart)}
      ''
    )
  );
  xdg.systemDirs.data = lib.optionals (!isNixOS) [
    "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
    "/var/lib/flatpak/exports/share"
  ];
}
