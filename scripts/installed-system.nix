# Read only the stateful defaults and bootloader from the installed configuration.
{
  nixpkgs,
  username,
  hostName,
  configurationDirectory ? /etc/nixos,
}:
let
  existingFlake = builtins.getFlake "path:${toString configurationDirectory}";
  configurations = existingFlake.nixosConfigurations;
  names = builtins.attrNames configurations;
  installed =
    if builtins.pathExists (configurationDirectory + "/flake.nix") then
      if builtins.hasAttr hostName configurations then
        configurations.${hostName}.config
      else if builtins.length names == 1 then
        configurations.${builtins.head names}.config
      else
        throw "Cannot select the installed host from /etc/nixos/flake.nix"
    else
      (nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ (configurationDirectory + "/configuration.nix") ];
      }).config;
  loader = installed.boot.loader;
in
{
  stateVersion = installed.system.stateVersion;
  homeStateVersion =
    installed.home-manager.users.${username}.home.stateVersion or installed.system.stateVersion;
  # Carry the standard boot target, never store old derivations or generated scripts.
  bootLoader =
    if loader.systemd-boot.enable || loader.grub.enable then
      {
        inherit (loader) timeout;
        efi = { inherit (loader.efi) canTouchEfiVariables efiSysMountPoint; };
        systemd-boot.enable = loader.systemd-boot.enable;
        grub = {
          inherit (loader.grub)
            enable
            efiSupport
            efiInstallAsRemovable
            useOSProber
            mirroredBoots
            ;
        };
      }
    else
      throw "Automatic setup supports installed systemd-boot or GRUB; configure nixos/local-system.json for this bootloader first";
}
