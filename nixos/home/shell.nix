{
  pkgs,
  config,
  isNixOS,
  lib,
  desktopEnabled ? false,
  ...
}:
let
  aliases = config.home.shellAliases;
  aliasLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: command: "alias ${name}=${lib.escapeShellArg command}") aliases
  );
  common = ''
    export PATH="$HOME/.local/bin:$PATH"
    ${aliasLines}
    if [ -z "''${LS_COLORS:-}" ] && command -v dircolors >/dev/null 2>&1; then
      eval "$(dircolors -b)"
    fi
    if command -v eza >/dev/null 2>&1; then
      alias ls='eza --icons=auto --group-directories-first'
      alias ll='eza -l --icons=auto --group-directories-first'
      alias la='eza -la --icons=auto --group-directories-first'
    else
      alias ls='ls --color=auto'
      alias ll='ls -l --color=auto'
      alias la='ls -la --color=auto'
    fi
    alias grep='grep --color=auto'
    if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook "$shell_kind")"; fi
    if command -v starship >/dev/null 2>&1; then eval "$(starship init "$shell_kind")"; fi
    if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init "$shell_kind")"; fi
    if command -v fzf >/dev/null 2>&1; then
      if [ "$shell_kind" = zsh ]; then source <(fzf --zsh); else eval "$(fzf --bash)"; fi
    fi
    theme="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/theme"
    [ ! -r "$theme/fzf.sh" ] || . "$theme/fzf.sh"
    if [ -r "$theme/lazygit.yml" ]; then
      export LG_CONFIG_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml,$theme/lazygit.yml"
    fi
    y() {
      local tmp cwd exit_code=0
      tmp=$(mktemp)
      command yazi "$@" --cwd-file="$tmp" || exit_code=$?
      cwd=$(cat "$tmp")
      rm -f "$tmp"
      if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then cd -- "$cwd"; fi
      return "$exit_code"
    }
  '';
in
{
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ]
  ++ lib.optional (!isNixOS) "${config.home.profileDirectory}/bin";
  home.sessionSearchVariables = lib.optionalAttrs (!isNixOS) {
    XDG_DATA_DIRS = [
      "${config.home.profileDirectory}/share"
      "/usr/local/share"
      "/usr/share"
    ];
  };
  home.shellAliases = {
    lt = "eza --tree --level=2";
    edit = "sudo -e";
  };
  home.file.".zshenv".text = ''
    if [ -r "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    fi
  '';
  home.file.".zshrc".text = ''
    HISTFILE="$HOME/.zsh_history"
    HISTSIZE=10000
    SAVEHIST=10000
    setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY
    autoload -Uz colors compinit
    colors
    compinit
    shell_kind=zsh
    ${common}
    zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
    # Load highlighting last, after tools have registered their ZLE widgets.
    ${
      if isNixOS then
        ''
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ''
      else
        ''
          for plugin in zsh-autosuggestions/zsh-autosuggestions.zsh zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
            for prefix in /usr/share /usr/local/share /usr/share/zsh/plugins; do
              if [ -r "$prefix/$plugin" ]; then
                source "$prefix/$plugin"
                break
              fi
            done
          done
        ''
    }
  '';
  programs.bash = {
    enable = true;
    package = null;
    initExtra = ''
      shell_kind=bash
      ${common}
    '';
  };
  xdg.configFile."direnv/direnvrc".text = ''
    for candidate in /usr/share/nix-direnv/direnvrc /run/current-system/sw/share/nix-direnv/direnvrc; do
      if [ -r "$candidate" ]; then source "$candidate"; break; fi
    done
  '';
  xdg.configFile."lazygit/config.yml".text = "{}\n";
  xdg.configFile."bat/config".text = (
    if desktopEnabled then "--theme=noctalia\n" else "--theme=base16\n"
  );
  programs.btop = {
    enable = true;
    package = null;
    settings.color_theme = if desktopEnabled then "noctalia" else "Default";
  };
}
