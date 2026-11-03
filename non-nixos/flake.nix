{
  description = "Dotfiles only for native Linux apps; independent of the NixOS configuration";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forSystems = nixpkgs.lib.genAttrs systems;
      packages = forSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          apply = pkgs.writeShellApplication {
            name = "dotfiles-apply";
            runtimeInputs = [
              pkgs.gitMinimal
              pkgs.python3
            ];
            text = ''exec python3 ${./apply.py} "$@"'';
          };
          update = pkgs.writeShellApplication {
            name = "dotfiles-update";
            runtimeInputs = [ apply ];
            text = ''exec dotfiles-apply --update "$@"'';
          };
        in
        {
          default = apply;
          inherit update;
        }
      );
    in
    {
      inherit packages;
      apps = forSystems (system: {
        default = {
          type = "app";
          program = "${packages.${system}.default}/bin/dotfiles-apply";
          meta.description = "Apply desktop and shell dotfiles";
        };
        update = {
          type = "app";
          program = "${packages.${system}.update}/bin/dotfiles-update";
          meta.description = "Fast-forward the checkout and update unedited dotfiles";
        };
      });
    };
}
