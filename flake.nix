{
  description = "NixOS workstation, portable Linux home and project development shells";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Keep the cache branch and independent nixpkgs pin to match cached builds.
    # Cache settings live in system/nix.nix.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter/v1.7.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-templates = {
      url = "github:noctalia-dev/community-templates/2f2ada3f10a66f9dbeb2136e4d70271ac6072aaf";
      flake = false;
    };
    millennium.url = "github:SteamClientHomebrew/Millennium/63c3928f0306edd83122c0f5b085a9b1a3d60f55?dir=packages/nix&narHash=sha256-%2BmNY2lHscvVa4KntAxuRMMFYMYxju06avIKyHooM8EE%3D";
    noctalia-plugins = {
      url = "github:noctalia-dev/community-plugins/aa42b35d2e89550bd2d516718f2c29bccddbe0dc";
      flake = false;
    };
    # Keep the tested action syntax and matching wlroots/portal dependency pins.
    umbriel.url = "github:noctalia-dev/umbriel/b1c3efc407c4cbc8db265bd678eddc13261553c3";
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.7.0";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL/b6105297e6f0cd041670c3e8628394d4ee247ed5";
      flake = false;
    };
    webos-dev-manager.url = "github:OmarDardery/dev-manager-desktop/b7afa5dc41b46d057db751dcbc32e70ef3d57d60";
  };
  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      profile = import ./nixos/profile.nix;
      inherit (profile) system;
      pkgs = import nixpkgs {
        inherit system;
        config = import ./nixos/package-policy.nix;
      };
      homeProfiles = {
        "${profile.username}" = {
          development = true;
          gaming = true;
          desktop = false;
        };
        "${profile.username}-core" = {
          development = false;
          gaming = false;
          desktop = false;
        };
        "${profile.username}-dev" = {
          development = true;
          gaming = false;
          desktop = false;
        };
        "${profile.username}-gaming" = {
          development = false;
          gaming = true;
          desktop = false;
        };
        "${profile.username}-desktop" = {
          development = true;
          gaming = true;
          desktop = true;
        };
      };
      apply = pkgs.writeShellApplication {
        name = "config-apply";
        runtimeInputs = [
          pkgs.gitMinimal
          pkgs.coreutils
          pkgs.util-linux
          pkgs.jq
        ];
        text = builtins.readFile ./scripts/apply.sh;
      };
    in
    {
      lib.deployment = profile;
      packages.${system} = {
        home-manager = home-manager.packages.${system}.home-manager;
        default = apply;
      };
      apps.${system}.default = {
        type = "app";
        program = "${apply}/bin/config-apply";
        meta.description = "Apply the NixOS system or Linux Home Manager profile for the current user";
      };
      formatter.${system} = pkgs.nixfmt-tree;
      devShells.${system} = import ./nixos/dev-shells.nix { inherit pkgs; };
      templates = builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value = {
              path = ./templates + "/${name}";
              description = "Standalone ${name} project shell with direnv";
            };
          })
          [
            "nix"
            "python"
            "go"
            "node"
            "rust"
            "cpp"
          ]
      );
      homeConfigurations = nixpkgs.lib.mapAttrs (
        name: features:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs features;
            profile = profile // {
              profileName = name;
            };
            isNixOS = false;
            isLaptop = false;
            desktopEnabled = features.desktop;
          };
          modules = [
            ./nixos/home
            {
              targets.genericLinux = {
                enable = true;
                gpu.enable = false;
              };
            }
          ];
        }
      ) homeProfiles;
      nixosConfigurations.${profile.hostName} = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs profile;
          isNixOS = true;
          isLaptop = true;
        };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
