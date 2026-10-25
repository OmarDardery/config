{ pkgs, ... }:
{
  environment.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";
  programs.nix-ld.enable = true; # provides /lib64/ld-linux for foreign binaries
  programs.nix-ld.libraries = (import ../lib/toolchain.nix { inherit pkgs; }).pythonNativeLibraries;
  services.udev.packages = [
    pkgs.platformio-core.udev
  ];

  # Docker daemon and container virtualization
  virtualisation.docker = {
    enable = true;
    # The socket starts Docker when WinBoat or a development client needs it.
    enableOnBoot = false;
    # BuildKit cache only: leave containers, images and volumes alone.
    daemon.settings.builder.gc = {
      enabled = true;
      defaultKeepStorage = "15GB";
    };
  };
}
