{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Shared shell dotfiles already initialize the hook.
    enableBashIntegration = false;
    enableZshIntegration = false;
  };
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  fonts.fontconfig.enable = true;
}
