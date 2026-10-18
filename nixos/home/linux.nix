# Portable shell and development tools; the distribution owns the desktop.
{ pkgs, ... }:
{
  imports = [ ./default.nix ];
  targets.genericLinux = {
    enable = true;
    gpu.enable = false;
  };
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
