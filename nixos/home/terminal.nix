{
  pkgs,
  inputs,
  config,
  lib,
  isNixOS,
  ...
}:
{
  programs.fastfetch = {
    enable = true;
    package =
      if isNixOS then
        (import ../pkgs/noctalia-app-themes.nix {
          inherit pkgs lib config;
          templates = inputs.noctalia-templates;
        }).fastfetch
      else
        pkgs.fastfetch;
  };
  home.packages = with pkgs; [
    curl
    wget
    jq
    file
    rsync
    zip
    unzip
    _7zz
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
}
