{
  profile,
  isLaptop,
  lib,
  ...
}:
let
  repository = lib.escapeShellArg "path:${profile.configRepo}";
  directory = lib.escapeShellArg profile.configRepo;
  arguments = " -- --repo-dir ${directory} --host ${lib.escapeShellArg profile.hostName}";
  applyCommand = "nix run ${repository}${arguments}";
  updateCommand = "nix run ${lib.escapeShellArg "path:${profile.configRepo}#update"}${arguments}";
in
{
  home.sessionVariables.NH_FLAKE = "path:${profile.configRepo}";
  home.shellAliases = {
    update = updateCommand;
    up = applyCommand;
    rebuild = applyCommand;
    nbuild = "${applyCommand} --build-only";
    neval = "nix flake check ${repository} --no-build --no-write-lock-file";
    nupdate = "nix flake update --flake ${repository}";
    nfmt = "(cd ${directory} && nix fmt --no-write-lock-file)";
    cnf = "\${EDITOR:-nvim} ${directory}";
    cconf = "cd ${directory}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
