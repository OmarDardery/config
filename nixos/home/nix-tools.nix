# Nix tooling and deployment aliases for both backends.
{
  profile,
  isNixOS,
  isLaptop,
  lib,
  ...
}:
let
  repository = lib.escapeShellArg "path:${profile.configRepo}";
  directory = lib.escapeShellArg profile.configRepo;
  prepareHardware = "bash ${lib.escapeShellArg "${profile.configRepo}/native/copy-hardware.sh"} ${lib.escapeShellArg (builtins.dirOf profile.configRepo)} --if-missing";
  switchCommand =
    if isNixOS then
      "${prepareHardware} && nh os switch --hostname ${lib.escapeShellArg profile.hostName} ${repository}"
    else
      "nix run ${repository}#home-manager -- switch --flake ${lib.escapeShellArg "path:${profile.configRepo}#${profile.profileName}"}";
  updateCommand = "config-update ${directory} ${if isNixOS then "os" else "home"} ${
    lib.escapeShellArg (if isNixOS then profile.hostName else profile.profileName)
  }";
in
{
  xdg.configFile."nix/nix.conf" = {
    enable = !isNixOS;
    text = "experimental-features = nix-command flakes\n";
  };
  home.file.".local/bin/config-update" = {
    executable = true;
    text = "#!/usr/bin/env bash\n" + builtins.readFile ../pkgs/config-update.sh;
  };
  home.file.".local/bin/office-convert" = {
    executable = true;
    text = "#!/usr/bin/env python3\n" + builtins.readFile ../pkgs/office-convert.py;
  };
  home.file.".local/bin/notebook-kernel" = {
    executable = true;
    text = "#!/usr/bin/env python3\n" + builtins.readFile ../pkgs/notebook-kernel.py;
  };
  home.sessionVariables.NH_FLAKE = "path:${profile.configRepo}";
  home.shellAliases = {
    update = updateCommand;
    up = switchCommand;
    rebuild = switchCommand;
    nbuild =
      if isNixOS then
        "${prepareHardware} && nh os build --hostname ${lib.escapeShellArg profile.hostName} ${repository}"
      else
        "nix build ${lib.escapeShellArg "path:${profile.configRepo}#homeConfigurations.${profile.profileName}.activationPackage"}";
    neval = "nix flake check ${repository} --no-build --no-write-lock-file";
    ncheck = "nix flake check ${repository} --no-write-lock-file";
    nupdate = "nix flake update --flake ${repository}";
    nfmt = "(cd ${directory} && nix fmt --no-write-lock-file)";
    cnf = "\${EDITOR:-nvim} ${directory}";
    cconf = "cd ${directory}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
