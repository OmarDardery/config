{
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
    # Keep Umbriel's wlroots and portal dependencies together on its own pin.
    umbriel.url = "github:noctalia-dev/umbriel";
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
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      profile = import ./profile.nix;
      inherit (profile) system;
      pkgs = import nixpkgs {
        inherit system;
        config = import ./package-policy.nix;
      };
    in
    {
      lib.deployment = profile;
      packages.${system}.home-manager = home-manager.packages.${system}.home-manager;
      formatter.${system} = pkgs.nixfmt-tree;
      checks.${system} = import ./checks.nix {
        inherit pkgs inputs;
        flake = inputs.self;
      };
      devShells.${system} = import ./dev-shells.nix { inherit pkgs; };
      homeConfigurations = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit inputs;
              profile = profile // { profileName = name; };
              isNixOS = false;
              isLaptop = false;
              desktopEnabled = true;
            };
            modules = [
              ./home
              {
                targets.genericLinux = {
                  enable = true;
                  gpu.enable = false;
                };
              }
            ];
          };
        }) [ profile.profileName "${profile.profileName}-desktop" ]
      );
      nixosConfigurations.${profile.hostName} = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs profile;
          isNixOS = true;
          isLaptop = true;
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
