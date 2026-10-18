{
  inputs,
  lib,
  config,
  isNixOS,
  osConfig ? { },
  ...
}:
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  # NixOS owns Flatpak and its helper; Home Manager owns user apps/remotes.
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
