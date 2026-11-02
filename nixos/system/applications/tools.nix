{
  isNixOS,
  isLaptop,
  pkgs,
  config,
  lib,
  profile,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      (import ../../pkgs/performance-launchers.nix { inherit pkgs isNixOS isLaptop; }).performanceRun
      kitty
      starship
      zoxide
      fzf
      bat
      eza
      lazygit
      btop
      yazi
      ripgrep
      fd
      tealdeer
      git
      git-lfs
      delta
      gh
      nh
      nix-output-monitor
      nvd
      nix-tree
      curl
      wget
      jq
      file
      rsync
      zip
      unzip
      _7zz
      zsh-autosuggestions
      zsh-syntax-highlighting
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
  environment.sessionVariables.NH_FLAKE = "path:${profile.configRepo}";
}
