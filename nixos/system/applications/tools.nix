{
  pkgs,
  profile,
  ...
}:
let
  toolchain = import ../../lib/toolchain.nix { inherit pkgs; };
in
{
  environment.systemPackages =
    with pkgs;
    [
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
      direnv
      nix-direnv
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
      opencode
      platformio-core
      zsh-autosuggestions
      zsh-syntax-highlighting
      (callPackage ../../pkgs/antigravity-cli.nix { })
    ]
    ++ toolchain.runtimes;
  environment.sessionVariables.NH_FLAKE = "path:${profile.configRepo}";
}
