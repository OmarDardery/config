# Host/backend settings; standalone Linux does not assume this laptop's disks.
{
  profile,
  isNixOS,
  isLaptop,
  lib,
  ...
}:
{
  programs.nh.flake = "path:${profile.configRepo}";

  home.shellAliases = {
    up =
      if isNixOS then
        "nh os switch --hostname ${lib.escapeShellArg profile.hostName}"
      else
        "nh home switch -c ${lib.escapeShellArg profile.profileName}";
    cnf = "\${EDITOR:-nvim} ${lib.escapeShellArg "${profile.configRepo}/${if isNixOS then "configuration.nix" else "profile.nix"}"}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
