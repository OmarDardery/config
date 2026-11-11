# Keep Nix available for activation commands and project development tools.
if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [[ -r $HOME/.nix-profile/etc/profile.d/nix.sh ]]; then
  source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
# Load Home Manager environment variables, including native Linux integration.
[[ ! -r $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh ]] || source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
# Home Manager supplies the desktop apps and optional shell integrations.
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

alias up='config-apply --update'
alias rebuild=config-apply
# Share completion, navigation and aliases with NixOS.
[[ ! -r ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/common.zsh ]] ||
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/common.zsh"

if (( $+commands[fzf] )); then
  source <(fzf --zsh 2>/dev/null)
fi
if (( $+commands[starship] )); then eval "$(starship init zsh)"; fi
if (( $+commands[zoxide] )); then eval "$(zoxide init zsh)"; fi
if (( $+commands[direnv] )); then eval "$(direnv hook zsh)"; fi
# Keep machine-specific additions outside the managed defaults.
[[ ! -f ${ZDOTDIR:-$HOME}/.zshrc.local ]] || source "${ZDOTDIR:-$HOME}/.zshrc.local"
