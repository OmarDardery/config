# Reuse the workstation's nixpkgs pin without fetching its desktop flake inputs.
let
  lock = builtins.fromJSON (builtins.readFile ./nixos/flake.lock);
  source = lock.nodes.${lock.nodes.root.inputs.nixpkgs}.locked;
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/${source.owner}/${source.repo}/archive/${source.rev}.tar.gz";
    sha256 = source.narHash;
  };
in
import ./nixos/dev-shell.nix { pkgs = import nixpkgs { }; }
