{
  pkgs,
  inputs,
  profile,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 2;
  boot.loader.efi.canTouchEfiVariables = true;
  # Bound kernel/initrd retention on the 1 GB EFI partition.
  boot.loader.systemd-boot.configurationLimit = 10;

  users.users.${profile.username} = {
    isNormalUser = true;
    home = profile.homeDirectory;
    description = profile.displayName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "recording"
      "wireshark"
    ];
    shell = pkgs.zsh;
  };

  # NixOS installs the login shell; Home Manager writes its dotfiles.
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;
  # The shared .zshrc initializes completion once.
  programs.zsh.enableGlobalCompInit = false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs profile;
      isNixOS = true;
      desktopEnabled = true;
      isLaptop = true;
    };
    backupFileExtension = "bak";
    users.${profile.username}.imports = [
      ../home
      ../home/hardware-user.nix
    ];
  };

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
