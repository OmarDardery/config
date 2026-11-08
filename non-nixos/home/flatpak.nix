# Native Flatpak keeps the distro's sandbox, portal and GPU integration.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.flatpak;
  installer = pkgs.writeShellApplication {
    name = "desktop-flatpaks";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = builtins.readFile ../flatpaks.sh;
  };
in
{
  options.desktop.flatpak = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the declared user Flatpaks during Home Manager activation";
    };
    installer = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = installer;
      description = "Synchronous native Flatpak installer";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "com.github.xournalpp.xournalpp"
        "org.libreoffice.LibreOffice"
        "app.zen_browser.zen"
      ] ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
        "com.valvesoftware.Steam"
        "com.vysp3r.ProtonPlus"
        "com.orcaslicer.OrcaSlicer"
        "com.discordapp.Discord"
      ];
      description = "Flathub application IDs; Steam/ProtonPlus are x86_64-only";
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ installer ];
    xdg.systemDirs.data = [
      "${config.xdg.dataHome}/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
    ];
    home.activation.desktopFlatpaks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/env \
        XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome} \
        XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
        XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
        ${installer}/bin/desktop-flatpaks ${lib.escapeShellArgs cfg.packages}
    '';
  };
}
