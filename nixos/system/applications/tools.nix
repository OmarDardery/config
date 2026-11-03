{
  pkgs,
  config,
  lib,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      curl
      jq
      file
      rsync
      zip
      unzip
      _7zz
    ]
    ++ lib.optionals config.workstation.diagnostics.enable (
      with pkgs;
      [
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
      ]
    );
}
