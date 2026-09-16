# To enable this package:
#   1. Uncomment nixpkgs-unstable in ../../flake.nix.
#   2. Uncomment this module's import in ../default.nix.
#   3. Run `nix flake lock` to lock the newly enabled input.
{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.brave-origin
  ];
}
