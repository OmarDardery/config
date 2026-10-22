{ config, inputs, ... }:
let
  modules = config.flake.modules;
in
{
  flake.modules.homeManager.portable = {
    imports = [
      ../home/default.nix
      modules.homeManager.dotfiles
      modules.homeManager.editors
    ];
    targets.genericLinux = {
      enable = true;
      gpu.enable = false;
    };
  };
  flake.modules.homeManager.desktop = {
    imports = [
      ../home/default.nix
      modules.homeManager.dotfiles
      modules.homeManager.editors
      modules.homeManager.desktop-dotfiles
    ];
  };
  flake.modules.nixos.workstation = {
    imports = [
      ../configuration.nix
      modules.nixos.desktop
      modules.nixos.greeter
      modules.nixos.applications
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
