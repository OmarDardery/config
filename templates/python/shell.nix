{ pkgs }:
pkgs.mkShell {
  name = "python-development";
  packages = with pkgs; [
    git
    gnumake
    pkg-config
    python3
    uv
    ruff
    pyright
  ];
  UV_PYTHON = "${pkgs.python3}/bin/python3";
  UV_PYTHON_DOWNLOADS = "never";
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
  ];
}
