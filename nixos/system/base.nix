{
  pkgs,
  profile,
  lib,
  ...
}:
{
  boot.loader.timeout = lib.mkDefault 2;
  # Bound kernel/initrd retention on the 1 GB EFI partition.
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  users.users.${profile.username} = {
    isNormalUser = true;
    home = profile.homeDirectory;
    description = profile.displayName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
    ];
    shell = pkgs.zsh;
  };

  # NixOS installs the login shell; Home Manager writes its dotfiles.
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;
  # Home Manager owns completion initialization.
  programs.zsh.enableGlobalCompInit = false;

  # Cairo timezone with English application formats.
  time.timeZone = "Africa/Cairo";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    RuntimeMaxUse=256M
    MaxRetentionSec=1month
  '';
}
