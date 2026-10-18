{
  pkgs,
  inputs,
  profile,
  ...
}:
{
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 2;
  boot.loader.efi.canTouchEfiVariables = true;
  # Bound kernel/initrd retention on the 1 GB EFI partition.
  boot.loader.systemd-boot.configurationLimit = 10;

  # Users
  users.users.${profile.username} = {
    isNormalUser = true;
    home = profile.homeDirectory;
    description = profile.displayName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "docker"
      "recording"
      "wireshark"
    ];
    shell = pkgs.zsh;
  };

  # Stub only — NixOS requires the shell to be enabled here for
  # the configured login shell above. All zsh config lives in home/shell.nix.
  programs.zsh.enable = true;
  # Home Manager initializes completion after adding its own completion paths.
  programs.zsh.enableGlobalCompInit = false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs profile;
      isNixOS = true;
      isLaptop = true;
    };
    backupFileExtension = "bak";
    users.${profile.username} = ../home/nixos.nix;
  };

  # Locale
  # Location and locale are independent: keep Cairo's clock and timezone,
  # while applications consistently use English text, digits, and formats.
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
