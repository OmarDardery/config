# Tooling for working on this config and on Nix projects generally. Portable:
# the one machine-specific bit, which flake `nh` acts on, lives in host.nix.
{ pkgs, inputs, ... }:
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

  home.packages = with pkgs; [
    nix-output-monitor # `nom`, readable build progress
    nvd # diff two generations' package lists
    nix-tree # walk a closure to find what pulled something in
  ];
}
