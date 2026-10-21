{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  # NixOS owns Flatpak and its helper; Home Manager owns user apps/remotes.
  xdg.systemDirs.data = [
    "${config.xdg.dataHome}/flatpak/exports/share"
    "/var/lib/flatpak/exports/share"
  ];
  # Network installs must not hold Home Manager's reloadSystemd stage open.
  # systemd still tracks failures and retries the upstream installer normally.
  systemd.user.services.flatpak-managed-install.Service.Type = lib.mkForce "exec";
  systemd.user.services.flatpak-managed-install-timer.Service.Type = lib.mkForce "exec";

  services.flatpak = {
    enable = true;
    packages = [
      "com.orcaslicer.OrcaSlicer"
      "com.vysp3r.ProtonPlus"
    ];
    uninstallUnmanaged = false;
    uninstallUnused = false;
    update.auto.enable = true;
  };
}
