{
  flake.modules.homeManager.desktop-dotfiles = { inputs, ... }: {
    imports = [
      inputs.noctalia.homeModules.default
      inputs.umbriel.homeModules.default
      ../home/desktop.nix
      ../home/files.nix
      ../home/noctalia.nix
      ../home/umbriel.nix
    ];
  };
  flake.modules.nixos.desktop = ../system/desktop.nix;
}
