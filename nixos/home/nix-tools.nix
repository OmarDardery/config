# Nix tooling and deployment aliases for both backends.
{
  pkgs,
  inputs,
  profile,
  isNixOS,
  isLaptop,
  lib,
  ...
}:
let
  repository = lib.escapeShellArg "path:${profile.configRepo}";
  directory = lib.escapeShellArg profile.configRepo;
  switchCommand =
    if isNixOS then
      "nh os switch --hostname ${lib.escapeShellArg profile.hostName}"
    else
      "nh home switch -c ${lib.escapeShellArg profile.profileName}";
in
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  # Wrapper around nixos-rebuild: progress output instead of a wall of text,
  # and it prints the package diff against the previous generation.
  programs.nh.enable = true;

  # Provides `nix-locate`, the "which package contains this binary" lookup.
  # It also wires up zsh's command-not-found handler. The imported module uses
  # a prebuilt database; no indexing is needed at activation or after updates.
  programs.nix-index.enable = true;
  # `, cowsay hi` runs a package once, using the same prebuilt database.
  programs.nix-index-database.comma.enable = true;

  # Per-project toolchains. With Rust, Go, bun and uv all in use side by side,
  # this keeps project-specific versions out of the global profile.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages =
    (with pkgs; [
      nix-output-monitor
      nvd
      nix-tree
    ])
    ++ lib.optional isNixOS (pkgs.callPackage ../pkgs/nixos-update.nix { });

  programs.nh.flake = "path:${profile.configRepo}";

  home.shellAliases = {
    up = switchCommand;
    rebuild = switchCommand;
    nbuild =
      if isNixOS then
        "nh os build --hostname ${lib.escapeShellArg profile.hostName}"
      else
        "nh home build -c ${lib.escapeShellArg profile.profileName}";
    neval = "nix flake check ${repository} --no-build --no-write-lock-file";
    ncheck = "nix flake check ${repository} --no-write-lock-file";
    nupdate = "nix flake update --flake ${repository}";
    nfmt = "(cd ${directory} && nix fmt --no-write-lock-file)";
    cnf = "\${EDITOR:-nvim} ${directory}";
    cconf = "cd ${directory}";
  }
  // lib.optionalAttrs isLaptop { lc = "cd /mnt/storage/Coding"; };
}
