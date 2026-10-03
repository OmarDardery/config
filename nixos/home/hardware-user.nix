{
  pkgs,
  lib,
  isLaptop,
  osConfig ? null,
  ...
}:
lib.mkIf isLaptop {
  home.packages = [
    pkgs.opentabletdriver
    # Integrated HM uses the exact host driver pin; no duplicate driver policy.
    (if osConfig != null then osConfig.hardware.nvidia.package.settings else pkgs.nvidia-settings)
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  systemd.user.services.opentabletdriver = {
    Unit = {
      Description = "Open source, cross-platform, user-mode tablet driver";
      After = [ "graphical-session.target" ];
      BindsTo = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "simple";
      ExecStart = lib.getExe' pkgs.opentabletdriver "otd-daemon";
      Restart = "on-failure";
    };
  };
}
