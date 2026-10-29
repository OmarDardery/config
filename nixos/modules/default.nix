# Plain NixOS/Home Manager modules; no registration framework.
let
  desktop = { inputs, ... }: {
    imports = [
      inputs.noctalia.homeModules.default
      inputs.umbriel.homeModules.default
      ../home
      ../home/editors
      ../home/desktop.nix
      ../home/files.nix
      ../home/noctalia.nix
      ../home/umbriel.nix
      ../home/yazi.nix
      ../home/office.nix
      ../home/shell.nix
      ../home/git.nix
      ../home/kitty.nix
      ../home/nix-tools.nix
    ];
  };
in
{
  homeManager = {
    inherit desktop;
    portable = {
      imports = [ desktop ];
      targets.genericLinux = {
        enable = true;
        gpu.enable = false;
      };
    };
  };
  nixos.workstation = { inputs, ... }: {
    imports = [
      ../configuration.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
