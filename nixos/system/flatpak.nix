# The standard module installs the declared applications at activation/boot.
{ inputs, ... }:
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    uninstallUnmanaged = false;
    uninstallUnused = false;
    update.onActivation = true;
    update.auto.enable = false;
  };
}
