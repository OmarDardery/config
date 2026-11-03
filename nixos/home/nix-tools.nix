{
  profile,
  pkgs,
  inputs,
  isLaptop,
  lib,
  ...
}:
let
  repository = lib.escapeShellArg "path:${profile.configRepo}";
  directory = lib.escapeShellArg profile.configRepo;
  applyCommand = "config-apply";
  updateCommand = "config-update";

in
{
  home.packages = [
    (pkgs.writeShellScriptBin "config-apply" ''
      exec ${
        inputs.self.packages.${profile.system}.default
      }/bin/config-apply --repo-dir ${directory} --host ${lib.escapeShellArg profile.hostName} "$@"
    '')
    (pkgs.writeShellScriptBin "config-update" ''
      exec ${
        inputs.self.packages.${profile.system}.default
      }/bin/config-apply --repo-dir ${directory} --host ${lib.escapeShellArg profile.hostName} --update "$@"
    '')
  ];
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
