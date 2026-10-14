{ pkgs }:
let
  toolchain = import ./home/development/toolchain.nix { inherit pkgs; };
  generalPackages = toolchain.runtimes;
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

  # Opt-in project-selected toolchains; downloads remain explicit rustup operations.
  rustup = pkgs.mkShell { packages = [ pkgs.rustup ]; };

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
