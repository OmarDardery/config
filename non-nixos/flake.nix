{
  description = "Standalone Home Manager desktop essentials for Linux";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, home-manager, ... }:
    let
      profile = import ./profile.nix;
      forSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs.profile = profile // {
            inherit system;
          };
          modules = [ ./home ];
        };
      home = mkHome profile.system;
      packages = forSystems (system: {
        default =
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          pkgs.writeShellApplication {
            name = "home-apply";
            runtimeInputs = [
              pkgs.gitMinimal
              pkgs.coreutils
              pkgs.util-linux
              pkgs.jq
              home-manager.packages.${system}.home-manager
            ];
            text = builtins.readFile ./apply.sh;
          };
      });
    in
    {
      inherit packages;
      homeConfigurations.${profile.username} = home;
      lib.deployment = profile;
      lib.hostRequirements.flatpak =
        home.config.desktop.flatpak.enable && home.config.desktop.flatpak.packages != [ ];
      checks = forSystems (system: {
        home = (mkHome system).activationPackage;
      });
      apps = forSystems (system: {
        default = {
          type = "app";
          program = "${packages.${system}.default}/bin/home-apply";
          meta.description = "Apply standalone Home Manager desktop essentials";
        };
      });
    };
}
