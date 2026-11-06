#!/usr/bin/env bash
# Bootstrap a checkout, then let standalone Home Manager own activation.
set -euo pipefail
repository=OmarDardery/config
repo_dir="${HOME:?HOME must be set}/config"
revision=
repository_selected=false
update_inputs=false
build_only=false
nixflags=(--extra-experimental-features 'nix-command flakes')
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'HELP'
Usage: nix run github:OmarDardery/config -- [OWNER/REPO] [OPTIONS]
Install Neovim/VSCodium and apply desktop dotfiles with standalone Home Manager.
  --repo-dir DIR  Checkout location (default: ~/config)
  --ref REF       Branch, tag or commit for a NEW checkout
  --update        Refresh the non-NixOS flake inputs before applying
  --build-only    Build the home generation without activating
  -h, --help      Show help
Run as your normal user on non-NixOS Linux. Native desktop apps stay native.
Existing checkouts keep source edits; pull repository changes with Git.
HELP
}
while (($#)); do
  case "$1" in
    --repo-dir|--ref)
      (($# >= 2)) && [[ -n "$2" && "$2" != -* ]] || die "$1 requires a value"
      case "$1" in --repo-dir) repo_dir=$2 ;; --ref) revision=$2 ;; esac
      shift 2 ;;
    --update) update_inputs=true; shift ;;
    --build-only) build_only=true; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [[ "$repository_selected" == false ]] || die 'provide only one repository'
       repository=$1; repository_selected=true; shift ;;
  esac
done
[[ $(id -u) != 0 ]] || die 'run as your normal user, without sudo'
[[ ! -e /etc/NIXOS ]] || die 'use the root NixOS flake on NixOS'
case $(uname -m) in
  x86_64) system=x86_64-linux ;;
  aarch64) system=aarch64-linux ;;
  *) die 'supported platforms: x86_64-linux and aarch64-linux' ;;
esac
repository=${repository#github:}; repository=${repository#https://github.com/}
repository=${repository%/}; repository=${repository%.git}
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'expected a GitHub OWNER/REPO'
repo_dir=$(realpath -m -- "$repo_dir")
[[ "$repo_dir" != *[\?#]* ]] || die 'checkout path cannot contain ? or #'
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
zsh_home="${ZDOTDIR:-$HOME}"
for directory in "$HOME" "$state_home" "$config_home" "$zsh_home"; do
  [[ "$directory" == /* ]] || die 'HOME, XDG and ZDOTDIR paths must be absolute'
done
mkdir -p -- "$state_home/non-nixos-config"
exec 9>"$state_home/non-nixos-config/apply.lock"
flock -n 9 || die 'another home apply is running'
if [[ -e "$repo_dir" || -L "$repo_dir" ]]; then
  [[ -d "$repo_dir/.git" || -f "$repo_dir/.git" ]] || die 'checkout path exists but is not a Git repository'
  origin=$(git -C "$repo_dir" remote get-url origin)
  origin=${origin#https://github.com/}; origin=${origin#git@github.com:}; origin=${origin%.git}
  [[ "$repository_selected" == false || "$origin" == "$repository" ]] || die 'checkout origin differs; select another --repo-dir'
  [[ -z "$revision" ]] || die '--ref only applies to a new checkout; switch existing branches with Git'
else
  mkdir -p -- "$(dirname -- "$repo_dir")"
  git clone -- "https://github.com/$repository.git" "$repo_dir"
  [[ -z "$revision" ]] || git -C "$repo_dir" checkout "$revision"
fi
[[ -f "$repo_dir/non-nixos/flake.lock" && -f "$repo_dir/non-nixos/home/default.nix" ]] || die 'checkout needs the standalone Home Manager configuration; pull repository changes first'
profile="$repo_dir/non-nixos/local-profile.json"
if [[ ! -e "$profile" ]]; then
  temporary=$(mktemp "$repo_dir/non-nixos/.local-profile.XXXXXXXX")
  trap 'rm -f -- "$temporary"' EXIT
  jq -n --arg username "$(id -un)" --arg homeDirectory "$HOME" \
    --arg system "$system" --arg configRepo "$repo_dir" \
    --arg configHome "$config_home" --arg stateHome "$state_home" --arg zshHome "$zsh_home" \
    '{username:$username,homeDirectory:$homeDirectory,system:$system,configRepo:$configRepo,
      configHome:$configHome,stateHome:$stateHome,zshHome:$zshHome,stateVersion:"26.05"}' > "$temporary"
  mv -T -- "$temporary" "$profile"
fi
username=$(jq -er '.username' "$profile")
jq -e --arg username "$(id -un)" --arg home "$HOME" --arg system "$system" \
  '.username == $username and .homeDirectory == $home and .system == $system' "$profile" >/dev/null \
  || die 'local-profile.json belongs to a different user, home or architecture'
flake="path:$repo_dir/non-nixos"
if [[ "$update_inputs" == true ]]; then nix "${nixflags[@]}" flake update --flake "$flake"; fi
if [[ "$build_only" == true ]]; then
  nix "${nixflags[@]}" build --no-write-lock-file --no-link "$flake#homeConfigurations.$username.activationPackage"
else
  home-manager switch --flake "$flake#$username" --no-write-lock-file \
    --extra-experimental-features 'nix-command flakes' -b "before-home-manager-$(date +%s%N)"
fi
printf 'Checkout: %s\n' "$repo_dir"
