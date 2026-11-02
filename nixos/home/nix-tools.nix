{
  profile,
  isLaptop,
  lib,
  ...
}:
let
  repository = lib.escapeShellArg "path:${profile.configRepo}";
  directory = lib.escapeShellArg profile.configRepo;
  target = lib.escapeShellArg "path:${profile.configRepo}#${profile.hostName}";
  applyCommand = "sudo nixos-rebuild switch --flake ${target} --no-write-lock-file";
  updateCommand = "nix flake update --flake ${repository} && ${applyCommand}";

in
{
  home.shellAliases = {
    update = updateCommand;
    up = applyCommand;
    rebuild = applyCommand;
    nbuild = "nix build ${lib.escapeShellArg "path:${profile.configRepo}#nixosConfigurations.${profile.hostName}.config.system.build.toplevel"} --no-link --no-write-lock-file";
    neval = "nix flake check ${repository} --no-build --no-write-lock-file";
    nupdate = "nix flake update --flake ${repository}";
    nfmt = "(cd ${directory} && nix fmt --no-write-lock-file)";
    cnf = "\${EDITOR:-nvim} ${directory}";
    cconf = "cd ${directory}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
