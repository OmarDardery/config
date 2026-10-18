{
  pkgs,
  lib,
  isNixOS,
  ...
}:
{
  home.packages =
    (with pkgs; [
      curl
      wget
      jq
      file
      rsync
      zip
      unzip
      _7zz
      fastfetch
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
    ])
    ++ lib.optional (!isNixOS) pkgs.mtr;
}
