# Shared Zsh navigation, completion and shell utilities.
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS HIST_REDUCE_BLANKS HIST_VERIFY HIST_EXPIRE_DUPS_FIRST

if [[ -o interactive ]]; then
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey '^[[A' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search
  bindkey '^[OA' up-line-or-beginning-search
  bindkey '^[OB' down-line-or-beginning-search
  bindkey '^[[1;5C' forward-word
  bindkey '^[[1;5D' backward-word
  zmodload zsh/complist
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
  zstyle ':completion:*:descriptions' format '%F{cyan}%d%f'
fi
if (( $+commands[eza] )); then
  alias ls='eza -al --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias ll='eza -l --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
  alias lta='eza -aT --group-directories-first'
  alias ldot="eza -a | grep '^[.]'"
else
  alias ll='ls -lah'
fi
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias jctl='journalctl -p 3 -xb'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
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
