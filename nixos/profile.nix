# Personal defaults; generated deployment identity stays local.
let
  local = if builtins.pathExists ./local-profile.nix then import ./local-profile.nix else { };
  installed =
    if builtins.pathExists ./local-system.json then
      builtins.fromJSON (builtins.readFile ./local-system.json)
    else
      { };
in
rec {
  username = local.username or "oad";
  homeDirectory = local.homeDirectory or "/home/${username}";
  configRepo = local.configRepo or "${homeDirectory}/config";
  hostName = local.hostName or "nixos";
  system = local.system or "x86_64-linux";
  storageUUID = local.storageUUID or null;
  hardwareProfile = local.hardwareProfile or "generic";
  stateVersion = installed.stateVersion or "26.05";
  homeStateVersion = installed.homeStateVersion or stateVersion;
  bootLoader =
    installed.bootLoader or {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  displayName = "Omar Dardery";
  gitName = "OmarDardery";
  gitEmail = "oadardery@gmail.com";
}
