# Shared Zsh navigation, completion and shell utilities.
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS HIST_REDUCE_BLANKS HIST_VERIFY HIST_EXPIRE_DUPS_FIRST
setopt BANG_HIST COMPLETE_IN_WORD AUTO_LIST AUTO_MENU

if [[ -o interactive ]]; then
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey '^[[A' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search
  bindkey '^[OA' up-line-or-beginning-search
  bindkey '^[OB' down-line-or-beginning-search
  # Fish-like history expansion: !! and !$ expand when Space is pressed.
  bindkey ' ' magic-space
  bindkey '^[.' insert-last-word
  bindkey '^[[1;5C' forward-word
  bindkey '^[[1;5D' backward-word
  zmodload zsh/complist
  zstyle ':completion:*' menu select
  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*:approximate:*' max-errors 'reply=(1)'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*' squeeze-slashes yes
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
alias tarnow='tar -acf'
alias untar='tar -xvf'
# Zsh native history with explicit timestamps.
alias history='fc -l -E 1'
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

# CachyOS Fish's 'done' behavior without an additional Zsh plugin.
# Report long-running interactive commands only when desktop notifications exist.
if [[ -o interactive && ( -n ${WAYLAND_DISPLAY:-} || -n ${DISPLAY:-} ) ]] &&
   (( $+commands[notify-send] )); then
  zmodload zsh/datetime
  autoload -Uz add-zsh-hook
  typeset -gF _cachy_command_started=0
  typeset -g _cachy_command_name=''
  _cachy_notify_start() {
    _cachy_command_started=$EPOCHREALTIME
    _cachy_command_name=${1%% *}
  }
  _cachy_notify_finish() {
    local exit_code=$?
    (( _cachy_command_started > 0 )) || return 0
    local -F elapsed=$(( EPOCHREALTIME - _cachy_command_started ))
    _cachy_command_started=0
    (( elapsed >= 10 )) || return 0
    local status='Finished'
    (( exit_code == 0 )) || status='Failed'
    notify-send -u low -- 'Terminal command' "${_cachy_command_name}: ${status} (${elapsed%.*}s)" >/dev/null 2>&1
    return 0
  }
  add-zsh-hook preexec _cachy_notify_start
  add-zsh-hook precmd _cachy_notify_finish
fi
