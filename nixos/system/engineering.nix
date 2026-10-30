{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
lib.mkIf config.workstation.engineering.enable {
  environment.systemPackages = with pkgs; [
    freecad
    logisim-evolution
    platformio-core
    inputs.webos-dev-manager.packages.${pkgs.stdenv.hostPlatform.system}.webos-dev-manager
  ];
  services.flatpak.packages = [ "com.orcaslicer.OrcaSlicer" ];
  services.udev.packages = [ pkgs.platformio-core.udev ];
}
