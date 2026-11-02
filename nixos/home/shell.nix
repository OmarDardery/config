{ pkgs, config, ... }:
{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  home.packages = with pkgs; [
    ripgrep
    fd
    tealdeer
  ];
  home.shellAliases = {
    lt = "eza --tree --level=2";
    edit = "sudo -e";
    grep = "grep --color=auto";
  };
  programs = {
    bash = {
      enable = true;
      package = null;
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        path = "${config.home.homeDirectory}/.zsh_history";
        size = 10000;
        save = 10000;
        share = true;
        ignoreAllDups = true;
      };
    };
    starship.enable = true;
    zoxide.enable = true;
    fzf.enable = true;
    eza = {
      enable = true;
      icons = "auto";
      extraOptions = [ "--group-directories-first" ];
    };
    bat.enable = true;
    btop.enable = true;
    lazygit.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
