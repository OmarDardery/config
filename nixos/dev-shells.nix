{ pkgs }:
let
  toolchain = import ./home/development/toolchain.nix { inherit pkgs; };
  generalPackages =
    toolchain.runtimes
    ++ (with pkgs; [
      rustup
    ]);
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

  python = pkgs.mkShell {
    packages = [
      pkgs.python3
      pkgs.uv
    ];
    # Scoped to this shell, not every desktop application or editor process.
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath toolchain.pythonNativeLibraries;
  };
}
