# Native programs only; every integration is optional.
typeset -U path
path=("$HOME/.local/bin" $path)
export EDITOR=nvim
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY INTERACTIVE_COMMENTS
bindkey -e
autoload -Uz compinit
compinit

alias up=config-apply
alias rebuild=config-apply
alias update=config-update
alias ll='ls -lah'

if (( $+commands[starship] )); then eval "$(starship init zsh)"; fi
if (( $+commands[zoxide] )); then eval "$(zoxide init zsh)"; fi
if (( $+commands[direnv] )); then eval "$(direnv hook zsh)"; fi
# Keep machine-specific additions outside the managed defaults.
[[ ! -f ${ZDOTDIR:-$HOME}/.zshrc.local ]] || source "${ZDOTDIR:-$HOME}/.zshrc.local"
