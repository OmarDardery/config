{
  description = "NixOS desktop and native Linux dotfiles";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Keep the cache branch and independent nixpkgs pin to match cached builds.
    # Cache settings live in system/nix.nix.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    # Keep the tested action syntax and matching wlroots/portal dependency pins.
    umbriel.url = "github:noctalia-dev/umbriel/b1c3efc407c4cbc8db265bd678eddc13261553c3";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      profile = import ./nixos/profile.nix;
      isLaptop = profile.hardwareProfile == "asus-tuf-a14";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forSystems = nixpkgs.lib.genAttrs systems;
      packages = forSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = import ./nixos/package-policy.nix;
          };
          nixosApply = pkgs.writeShellApplication {
            name = "nixos-apply";
            runtimeInputs = [
              pkgs.gitMinimal
              pkgs.coreutils
              pkgs.util-linux
              pkgs.jq
            ];
            text = builtins.readFile ./scripts/apply.sh;
          };
          apply = pkgs.writeShellApplication {
            name = "config-apply";
            text = ''
              if [[ -e /etc/NIXOS ]]; then
                ${
                  if system == "x86_64-linux" then
                    "exec ${nixosApply}/bin/nixos-apply \"$@\""
                  else
                    "echo 'The full NixOS desktop supports x86_64-linux only.' >&2; exit 1"
                }
              fi
              exec nix --extra-experimental-features 'nix-command flakes' run \
                --no-write-lock-file path:${./non-nixos} -- "$@"
            '';
          };
        in
        {
          default = apply;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") { nixos-apply = nixosApply; }
      );
    in
    {
      lib.deployment = profile;
      inherit packages;
      apps = forSystems (system: {
        default = {
          type = "app";
          program = "${packages.${system}.default}/bin/config-apply";
          meta.description = "Apply the NixOS desktop or native Linux dotfiles";
        };
      });
      formatter = forSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      nixosConfigurations.${profile.hostName} = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs profile;
          inherit isLaptop;
        };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
