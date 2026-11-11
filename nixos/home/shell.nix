{ pkgs, config, ... }:
{
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
  home.sessionVariables = {
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };
  home.packages = with pkgs; [
    ripgrep
    fd
    tealdeer
  ];
  home.shellAliases = {
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
      initContent = builtins.readFile ../../non-nixos/dotfiles/zsh/common.zsh + ''
        [[ ! -r ''${ZDOTDIR:-$HOME}/.zshrc.local ]] || source "''${ZDOTDIR:-$HOME}/.zshrc.local"
      '';
      syntaxHighlighting.enable = true;
      history = {
        path = "${config.home.homeDirectory}/.zsh_history";
        size = 10000;
        save = 10000;
        share = true;
        ignoreAllDups = true;
        extended = true;
      };
    };
    starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ../../non-nixos/dotfiles/starship.toml);
    };
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
