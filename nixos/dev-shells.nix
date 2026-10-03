{ pkgs }:
let
  toolchain = import ./home/development/toolchain.nix { inherit pkgs; };
  generalPackages =
    toolchain.runtimes
    ++ (with pkgs; [
      rustup
      gcc
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
}
