{ pkgs }:
pkgs.mkShell {
  name = "cpp-development";
  packages = with pkgs; [
    git
    gnumake
    pkg-config
    clang-tools
    cmake
    ninja
    gdb
  ];
}
