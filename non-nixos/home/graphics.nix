{ config, lib, pkgs, ... }:
let
  gpu = config.targets.genericLinux.gpu;
in
{
  # Own the prerequisite in the configuration, including direct HM switches.
  home.activation.setupHostGraphics = lib.mkIf gpu.enable (
    lib.hm.dag.entryBetween [ "linkGeneration" "checkExistingGpuDrivers" ] [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/env PATH=${lib.makeBinPath [ pkgs.coreutils ]}:/usr/bin:/bin:/usr/sbin:/sbin \
        ${pkgs.bash}/bin/bash ${../graphics.sh} \
        ${lib.escapeShellArg (toString gpu.drivers)} \
        ${lib.escapeShellArg (lib.getExe gpu.setupPackage)}
    ''
  );
}
