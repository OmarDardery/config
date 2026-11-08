{ profile, pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty
    starship
    zsh
    zoxide
    direnv
  ];
  home.sessionVariables.TERMINAL = "kitty";
  xdg.configFile = {
    "kitty/kitty.conf".source = ../dotfiles/kitty/kitty.conf;
    "starship.toml".source = ../dotfiles/starship.toml;
  };
  home.file.".zshrc" = {
    target = "${profile.zshHome}/.zshrc";
    source = ../dotfiles/zsh/.zshrc;
  };
}
