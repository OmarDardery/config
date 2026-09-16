{ pkgs }:
let
  generalPackages = with pkgs; [
    rustup
    go
    bun
    # Keep real Node beside Bun: Node-shebang tools can otherwise run through
    # Bun's Node-API compatibility layer and fail unexpectedly.
    nodejs
    uv
    python3
    gcc
  ];
  embeddedPackages = with pkgs; [
    platformio-core
    arduino-cli
  ];
in
{
  default = pkgs.mkShell {
    packages = generalPackages ++ embeddedPackages;
  };

  general = pkgs.mkShell {
    packages = generalPackages;
  };

  embedded = pkgs.mkShell {
    packages = embeddedPackages;
  };
}
