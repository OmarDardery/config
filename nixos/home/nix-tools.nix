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
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "config-doctor";
      runtimeInputs = with pkgs; [ coreutils gnugrep util-linux systemd ];
      text = builtins.readFile ../../scripts/doctor.sh;
    })
    (pkgs.writeShellScriptBin "config-apply" ''
      exec ${
        inputs.self.packages.${profile.system}.nixos-apply
      }/bin/nixos-apply --repo-dir ${directory} --host ${lib.escapeShellArg profile.hostName} "$@"
    '')
  ];
  home.shellAliases = {
    up = "config-apply --update";
    rebuild = "config-apply";
    nbuild = "nix build ${lib.escapeShellArg "path:${profile.configRepo}#nixosConfigurations.${profile.hostName}.config.system.build.toplevel"} --no-link --no-write-lock-file";
    neval = "nix flake check ${repository} --no-build --no-write-lock-file";
    nfmt = "(cd ${directory} && nix fmt --no-write-lock-file)";
    cnf = "\${EDITOR:-nvim} ${directory}";
    cconf = "cd ${directory}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
