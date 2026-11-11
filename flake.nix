{
  description = "NixOS desktop and standalone Linux home configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # Release branch contains kernels already built and published to the cache.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Keep the cache branch and independent nixpkgs pin to match cached builds.
    # Cache settings live in system/nix.nix.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    # Track upstream; flake.lock records the validated compositor and portal revisions.
    umbriel.url = "github:noctalia-dev/umbriel";
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
          meta.description = "Apply the NixOS desktop or standalone Linux home configuration";
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
