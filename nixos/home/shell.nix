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
    ls = "eza -al";
    la = "eza -a";
    ll = "eza -l";
    lt = "eza -aT";
    ldot = "eza -a | grep '^[.]'";
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "......" = "cd ../../../../..";
    jctl = "journalctl -p 3 -xb";
    psmem = "ps auxf | sort -nr -k 4";
    psmem10 = "ps auxf | sort -nr -k 4 | head -10";
    tarnow = "tar -acf";
    untar = "tar -xf";
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
      initContent = ''
        # Prefix-aware history navigation; preserve FZF Ctrl-R and Starship.
        autoload -Uz history-search-end
        zle -N history-beginning-search-backward-end history-search-end
        zle -N history-beginning-search-forward-end history-search-end
        bindkey '^[[A' history-beginning-search-backward-end
        bindkey '^[[B' history-beginning-search-forward-end
        bindkey '^[OA' history-beginning-search-backward-end
        bindkey '^[OB' history-beginning-search-forward-end
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word

        zmodload zsh/complist
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:descriptions' format '%F{cyan}%d%f'
        zstyle ':completion:*' squeeze-slashes true

        setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
        setopt EXTENDED_GLOB INTERACTIVE_COMMENTS
        setopt HIST_REDUCE_BLANKS HIST_VERIFY HIST_EXPIRE_DUPS_FIRST

        backup() {
          if (( $# != 1 )); then
            print -u2 'Usage: backup FILE'
            return 2
          fi
          cp -a -- "$1" "$1.bak"
        }
        copy() {
          if (( $# == 2 )) && [[ -d "$1" ]]; then
            command cp -R -- "$1" "$2"
          else
            command cp -- "$@"
          fi
        }
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
