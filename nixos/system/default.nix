{ ... }:
{
  imports = [
    ./backups.nix
    ./base.nix
    ./networking.nix
    ./nix.nix
    ./performance.nix
    ./gaming.nix
    ./engineering.nix
    ./containers.nix
    ./printing.nix
    ./diagnostics.nix
    ./tailscale.nix
    ./flatpak.nix
    ./desktop.nix
    ./greeter.nix
    ./applications
  ];
}
