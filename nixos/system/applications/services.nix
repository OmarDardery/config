{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  services.flatpak = {
    enable = true;
    packages = lib.optional config.workstation.engineering.enable "com.orcaslicer.OrcaSlicer"
      ++ lib.optional config.workstation.gaming.enable "com.vysp3r.ProtonPlus";
    uninstallUnmanaged = false;
    uninstallUnused = false;
    update.auto.enable = true;
  };
  # Keep network downloads outside switch-to-configuration's synchronous wait.
  systemd.services.flatpak-managed-install.serviceConfig.Type = lib.mkForce "exec";
  systemd.services.flatpak-managed-install-timer.serviceConfig.Type = lib.mkForce "exec";
  systemd.user.services.desktop-config = {
    description = "Initialize desktop application themes";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session-pre.target" ];
    unitConfig.ConditionPathExists = "%h/.local/bin/desktop-apply";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash %h/.local/bin/desktop-apply";
      RemainAfterExit = true;
    };
    path = [
      pkgs.bat
      pkgs.xfconf
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
  # Distribution-level user units run only inside graphical sessions.
  systemd.user.services.kdeconnect = {
    description = "KDE Connect";
    wantedBy = [ "graphical-session.target" ];
    bindsTo = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "org.kde.kdeconnect";
      ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
      Restart = "on-failure";
    };
  };
  systemd.user.services.mpris-proxy = {
    description = "Bluetooth media controls";
    wantedBy = [ "graphical-session.target" ];
    bindsTo = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionPathExists = "/sys/class/bluetooth";
    serviceConfig = {
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
