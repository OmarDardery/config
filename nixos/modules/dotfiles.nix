{
  flake.modules.homeManager.dotfiles = {
    imports = [
      ../home/yazi.nix
      ../home/office.nix
      ../home/shell.nix
      ../home/git.nix
      ../home/kitty.nix
      ../home/nix-tools.nix
    ];
  };
}
