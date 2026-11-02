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
  applyCommand =
    "nix run ${repository} -- --repo-dir ${directory}"
    + (
      if isNixOS then
        " --host ${lib.escapeShellArg profile.hostName}"
      else
        " --home --profile ${lib.escapeShellArg profile.profileName}"
    );
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
  home.sessionVariables.NH_FLAKE = "path:${profile.configRepo}";
  home.shellAliases = {
    update = updateCommand;
    up = applyCommand;
    rebuild = applyCommand;
    nbuild = "${applyCommand} --build-only";
    neval =
      if isNixOS then
        "nix flake check ${repository} --no-build --no-write-lock-file"
      else
        "nix eval --raw ${lib.escapeShellArg "path:${profile.configRepo}#homeConfigurations.${profile.profileName}.activationPackage.drvPath"} --no-write-lock-file";
    nupdate = "nix flake update --flake ${repository}";
    nfmt = "(cd ${directory} && nix fmt --no-write-lock-file)";
    cnf = "\${EDITOR:-nvim} ${directory}";
    cconf = "cd ${directory}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
