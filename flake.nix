{
  description = "NixOS workstation with Home Manager and project development shells";
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
      update = pkgs.writeShellApplication {
        name = "config-update";
        runtimeInputs = [ apply ];
        text = ''exec config-apply --update "$@"'';
      };
    in
    {
      lib.deployment = profile;
      packages.${system} = {
        default = apply;
        inherit update;
      };
      apps.${system} = {
        default = {
          type = "app";
          program = "${apply}/bin/config-apply";
          meta.description = "Build and apply NixOS with integrated Home Manager";
        };
        update = {
          type = "app";
          program = "${update}/bin/config-update";
          meta.description = "Update NixOS flake inputs, build and switch";
        };
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
      nixosConfigurations.${profile.hostName} = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs profile;
          isLaptop = true;
        };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
