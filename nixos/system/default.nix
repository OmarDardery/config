{ ... }:
{
  imports = [
    ./backups.nix
    ./base.nix
    ./networking.nix
    ./nix.nix
    ./performance.nix
    ./development.nix
    ./features.nix
    ./desktop.nix
    ./greeter.nix
    ./applications
  ];
}
