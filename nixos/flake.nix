{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Required by home/optional/brave-origin.nix when its import is enabled.
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Two things here are required for the binary cache to actually hit, and
    # both are easy to undo by accident:
    #   - the `cachix` branch, not `main`. CI force-pushes that branch to the
    #     commit it has finished building and uploading, so whatever you land
    #     on is guaranteed to be in the cache. `main` can be ahead of CI.
    #   - NO `inputs.nixpkgs.follows`. Overriding noctalia's inputs changes the
    #     derivation hash, so every build would miss the cache and compile from
    #     source. The cost is a second nixpkgs (it pins unstable).
    # Cache itself is configured in nix.settings in configuration.nix.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pixie-sddm = {
      url = "github:xCaptaiN09/pixie-sddm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    webos-dev-manager.url = "github:OmarDardery/dev-manager-desktop/b7afa5dc41b46d057db751dcbc32e70ef3d57d60";
    # Doom Emacs with every elisp package resolved by Nix. The older
    # nix-community/nix-doom-emacs is broken by its own admission and points
    # here. This one runs Doom's CLI to export its dependency list, then feeds
    # that to emacsWithPackages, so straight.el never runs.
    #
    # It pulls emacs-overlay, doomemacs/core and doomemacs/modules transitively.
    # Unlike noctalia this costs no second nixpkgs: emacs-overlay leaves its own
    # nixpkgs unset, so the `follows` below is inherited all the way down and
    # everything builds against 26.05.
    #nix-doom-emacs-unstraightened = {
    # url = "github:marienz/nix-doom-emacs-unstraightened";
    # inputs.nixpkgs.follows = "nixpkgs";
    #};
  };
  outputs =
    {
      self,
      nixpkgs,
      zen-browser,
      noctalia,
      home-manager,
      pixie-sddm,
      webos-dev-manager,
      #nix-doom-emacs-unstraightened,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      homePkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-40.10.5" ];
        };
      };
    in
    {
      devShells.${system} = import ./dev-shells.nix { inherit pkgs; };

      # The same Home Manager configuration can be activated directly on any
      # Linux distribution with Nix, without evaluating or rebuilding NixOS.
      homeConfigurations.oad = home-manager.lib.homeManagerConfiguration {
        pkgs = homePkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home ];
      };

      nixosConfigurations = {
        # Change "nixos" to your actual hostname if it is different
        "nixos" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
