{
  description = "Project development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { nixpkgs, ... }: {
    devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: {
      default = import ./shell.nix { pkgs = import nixpkgs { inherit system; }; };
    });
  };
}
