# Tooling for working on this config and on Nix projects generally. Portable:
# the one machine-specific bit, which flake `nh` acts on, lives in host.nix.
{ pkgs, ... }:
{
  # Wrapper around nixos-rebuild: progress output instead of a wall of text,
  # and it prints the package diff against the previous generation.
  programs.nh.enable = true;

  # Provides `nix-locate`, the "which package contains this binary" lookup.
  # It also wires up zsh's command-not-found handler. The database is not
  # built at activation — run `nix-index` once, and again after a big update.
  programs.nix-index.enable = true;

  # Per-project toolchains. With Rust, Go, bun and uv all in use side by side,
  # this keeps project-specific versions out of the global profile.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    comma # `, cowsay hi` runs a package once without installing it
    nix-output-monitor # `nom`, readable build progress
    nvd # diff two generations' package lists
    nix-tree # walk a closure to find what pulled something in
  ];
}
