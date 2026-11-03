{
  description = "NixOS workstation with Home Manager";
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
      inherit (profile) system;
      isLaptop = profile.hardwareProfile == "asus-tuf-a14";
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
