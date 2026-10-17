{ pkgs, ... }:
{
  programs.nix-ld.enable = true; # provides /lib64/ld-linux for foreign binaries
  programs.nix-ld.libraries =
    (import ../home/development/toolchain.nix { inherit pkgs; }).pythonNativeLibraries;
  services.udev.packages = [
    pkgs.platformio-core.udev
  ];

  # Docker daemon and container virtualization
  virtualisation.docker = {
    enable = true;
    # BuildKit cache only: leave containers, images and volumes alone.
    daemon.settings.builder.gc = {
      enabled = true;
      defaultKeepStorage = "15GB";
    };
  };
}
