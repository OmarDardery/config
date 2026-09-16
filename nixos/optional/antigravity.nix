# Import this module from configuration.nix to build and install `agy`.
{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: _prev: {
      antigravity-cli = final.callPackage ../pkgs/antigravity-cli.nix { };
    })
  ];

  home-manager.users.oad.home.packages = [ pkgs.antigravity-cli ];
}
