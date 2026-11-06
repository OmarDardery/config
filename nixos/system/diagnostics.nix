{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.workstation.diagnostics.enable = lib.mkEnableOption "host hardware, storage and network diagnostics";

  config = lib.mkIf config.workstation.diagnostics.enable {
    programs.mtr.enable = true;
    environment.systemPackages = with pkgs; [
      lshw
      usbutils
      pciutils
      lsof
      strace
      sysstat
      smartmontools
      nvme-cli
      dnsutils
      nmap
      iperf3
      ethtool
    ];
  };
}
