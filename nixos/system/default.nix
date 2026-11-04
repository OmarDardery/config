{ ... }:
{
  imports = [
    ./backups.nix
    ./base.nix
    ./networking.nix
    ./nix.nix
    ./performance.nix
    ./features.nix
    ./flatpak.nix
    ./desktop.nix
    ./greeter.nix
    ./applications
  ];
}
