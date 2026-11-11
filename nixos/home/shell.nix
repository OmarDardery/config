{ pkgs, config, lib, ... }:
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
    libnotify # notify-send, for long-command completion alerts
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
      autosuggestion = {
        enable = true;
        # Fish-like suggestions from both commands already used and completions.
        strategy = [ "history" "completion" ];
        highlight = "fg=#7c8493";
      };
      # compinit runs at 570; fzf-tab must load before autosuggestions at 700.
      initContent = lib.mkMerge [
        (lib.mkOrder 600 (builtins.readFile ../../non-nixos/dotfiles/zsh/common.zsh))
        (lib.mkOrder 650 ''
          source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
          zstyle ':fzf-tab:*' switch-group ',' '.'
          zstyle ':fzf-tab:*' fzf-flags --height=45% --border
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -a --color=always --icons=auto -- "$realpath" 2>/dev/null'
        '')
        (lib.mkOrder 720 ''
          # Ctrl+Space accepts the ghost-text suggestion; Right/End also work.
          bindkey '^@' autosuggest-accept
        '')
        (lib.mkOrder 1200 ''
          [[ ! -r ''${ZDOTDIR:-$HOME}/.zshrc.local ]] ||
            source "''${ZDOTDIR:-$HOME}/.zshrc.local"
        '')
      ];
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
