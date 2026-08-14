{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
    # Doom Emacs with every elisp package resolved by Nix. The older
    # nix-community/nix-doom-emacs is broken by its own admission and points
    # here. This one runs Doom's CLI to export its dependency list, then feeds
    # that to emacsWithPackages, so straight.el never runs.
    #
    # It pulls emacs-overlay, doomemacs/core and doomemacs/modules transitively.
    # Unlike noctalia this costs no second nixpkgs: emacs-overlay leaves its own
    # nixpkgs unset, so the `follows` below is inherited all the way down and
    # everything builds against 26.05.
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, zen-browser, noctalia, home-manager, pixie-sddm, nix-doom-emacs-unstraightened, ... }@inputs: {
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
