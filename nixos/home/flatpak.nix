{
  inputs,
  lib,
  pkgs,
  config,
  isNixOS,
  osConfig ? { },
  ...
}:
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  home.packages = [ pkgs.flatpak ];
  # User applications/remotes are Home Manager-owned. Keep older system exports
  # discoverable without enabling or managing the privileged system helper.
  xdg.systemDirs.data = [
    "${config.xdg.dataHome}/flatpak/exports/share"
    "/var/lib/flatpak/exports/share"
  ];
  services.flatpak = {
    enable = true;
    packages = [
      "com.orcaslicer.OrcaSlicer"
      "com.vysp3r.ProtonPlus"
    ]
    ++ lib.optionals (isNixOS && builtins.elem "nvidia" osConfig.services.xserver.videoDrivers) [
      # Prepare the configured driver before reboot, not just the loaded one.
      "org.freedesktop.Platform.GL.nvidia-${
        lib.replaceStrings [ "." ] [ "-" ] osConfig.hardware.nvidia.package.version
      }"
    ];
    uninstallUnmanaged = false;
    uninstallUnused = false;
    update.auto.enable = true;
  };
}
