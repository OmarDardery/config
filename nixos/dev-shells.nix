# Convenience shells reuse the self-contained project templates.
{ pkgs }:
{
  default = import ../templates/nix/shell.nix { inherit pkgs; };
  python = import ../templates/python/shell.nix { inherit pkgs; };
  go = import ../templates/go/shell.nix { inherit pkgs; };
  node = import ../templates/node/shell.nix { inherit pkgs; };
  rust = import ../templates/rust/shell.nix { inherit pkgs; };
  cpp = import ../templates/cpp/shell.nix { inherit pkgs; };
}
