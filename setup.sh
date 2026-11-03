#!/usr/bin/env bash
# Works from a checkout or as: curl -fsSL .../setup.sh | bash
set -euo pipefail
repository=OmarDardery/config
repo_dir="$HOME/config"
revision=
local_repo=
args=("$@")
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
  candidate=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  if [[ -f "$candidate/flake.nix" ]]; then local_repo=$candidate; repo_dir=$candidate; fi
fi
# Read only routing options; each installer validates its complete arguments.
while (($#)); do
  case "$1" in
    --repo-dir|--ref|--host|--hardware)
      (($# >= 2)) && [[ -n "$2" && "$2" != -* ]] || die "$1 requires a value"
      case "$1" in --repo-dir) repo_dir=$2 ;; --ref) revision=$2 ;; esac
      shift 2 ;;
    -*) shift ;;
    *) repository=$1; shift ;;
  esac
done
repository=${repository#github:}; repository=${repository#https://github.com/}
repository=${repository%/}; repository=${repository%.git}
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'expected OWNER/REPO'
if [[ -e /etc/NIXOS ]]; then
  flake="github:$repository${revision:+/$revision}"
  [[ -z "$local_repo" ]] || flake="path:$local_repo"
  exec nix --extra-experimental-features 'nix-command flakes' run "$flake" -- --repo-dir "$repo_dir" "${args[@]}"
fi
if [[ " ${args[*]} " == *' --help '* || " ${args[*]} " == *' -h '* ]]; then
  printf '%s\n' 'Dotfiles only: bash setup.sh [OWNER/REPO] [--repo-dir DIR] [--ref REF] [--update]' 'Requires native Git and Python 3.10+. No Nix or app installation.'
  exit 0
fi
[[ $(id -u) != 0 ]] || die 'run as your normal user, without sudo'
for program in git python3; do command -v "$program" >/dev/null || die "install $program through your distro package manager first"; done
if [[ ! -e "$repo_dir" && ! -L "$repo_dir" ]]; then
  mkdir -p -- "$(dirname -- "$repo_dir")"
  if [[ -z "$revision" ]]; then
    git clone --depth 1 -- "https://github.com/$repository.git" "$repo_dir"
  else
    git clone -- "https://github.com/$repository.git" "$repo_dir"
    git -C "$repo_dir" checkout "$revision"
  fi
  # The checkout now exists; --ref has already been applied.
  forwarded=()
  for ((i=0; i<${#args[@]}; i++)); do
    if [[ ${args[i]} == --ref ]]; then ((i+=1)); else forwarded+=("${args[i]}"); fi
  done
  args=("${forwarded[@]}")
fi
[[ -f "$repo_dir/non-nixos/apply.py" ]] || die 'checkout is missing non-nixos/apply.py'
exec python3 "$repo_dir/non-nixos/apply.py" --repo-dir "$repo_dir" "${args[@]}"
