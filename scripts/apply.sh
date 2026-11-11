#!/usr/bin/env bash
set -euo pipefail
repository=OmarDardery/config
repo_dir="${HOME:?HOME must be set}/config"
revision=
host=
hardware=
build_only=false
update_inputs=false
repository_selected=false
nixflags=(--extra-experimental-features 'nix-command flakes')
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'HELP'
Usage: nix run github:OmarDardery/config -- [OWNER/REPO] [OPTIONS]
Build and apply NixOS with integrated Home Manager. Requires NixOS.
  --repo-dir DIR  Checkout location (default: ~/config)
  --ref REF       Git branch, tag or commit for a NEW checkout
  --host NAME     NixOS configuration (default: profile.nix hostName)
  --hardware NAME generic or asus-tuf-a14 (default: detect the TUF A14)
  --update        Update flake inputs before building (used by up)
  --build-only    Build without switching the running system
  -h, --help      Show help
Repository accepts OWNER/REPO, github:OWNER/REPO, or an HTTPS GitHub URL.
Existing checkouts keep your source edits; pull source changes with Git.
up updates the checkout's flake.lock and applies the result.
Generated identity, bootloader, state versions and hardware stay local.
Other distros: the root nix run command automatically applies standalone Home Manager.
HELP
}
while (($#)); do
  case "$1" in
    --repo-dir|--ref|--host|--hardware)
      (($# >= 2)) && [[ -n "$2" && "$2" != -* ]] || die "$1 requires a value"
      case "$1" in
        --repo-dir) repo_dir=$2 ;;
        --ref) revision=$2 ;;
        --host) host=$2 ;;
        --hardware) hardware=$2 ;;
      esac
      shift 2 ;;
    --update) update_inputs=true; shift ;;
    --build-only) build_only=true; shift ;;
    --activate) shift ;; # Compatibility with the previous bootstrap command.
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *)
      [[ "$repository_selected" == false ]] || die 'provide only one repository'
      repository=$1; repository_selected=true; shift ;;
  esac
done
[[ $(id -u) != 0 ]] || die 'run as your normal user, not root or sudo'
[[ -e /etc/NIXOS ]] || die 'use the non-nixos flake on Fedora, Debian and other Linux distros'
[[ $(uname -m) == x86_64 ]] || die 'this workstation currently supports x86_64-linux only'
command -v nix >/dev/null || die 'install Nix first: https://nixos.org/download/'
repository=${repository#github:}
repository=${repository#https://github.com/}
repository=${repository%/}
repository=${repository%.git}
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'expected a GitHub OWNER/REPO or HTTPS repository URL; use --ref for a branch'
[[ -z "$host" || "$host" =~ ^[A-Za-z0-9_-]+$ ]] || die 'invalid host name'
[[ -z "$hardware" || "$hardware" == generic || "$hardware" == asus-tuf-a14 ]] || die 'unknown hardware profile'
username=$(id -un)
[[ "$username" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || die 'unsupported account name'
repo_dir=$(realpath -m -- "$repo_dir")
[[ "$repo_dir" != *[\?#]* ]] || die 'checkout path cannot contain ? or #'
lock_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix-config"
mkdir -p -- "$lock_dir"
exec 9>"$lock_dir/apply.lock"
flock -n 9 || die 'another configuration apply is running'
if [[ -e "$repo_dir" || -L "$repo_dir" ]]; then
  [[ -d "$repo_dir/.git" || -f "$repo_dir/.git" ]] || die "$repo_dir exists but is not a Git checkout"
  origin=$(git -C "$repo_dir" remote get-url origin)
  origin=${origin#https://github.com/}; origin=${origin#git@github.com:}; origin=${origin%.git}
  if [[ "$repository_selected" == false ]]; then repository=$origin; fi
  [[ "$origin" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'checkout origin must be a GitHub repository'
  [[ "$origin" == "$repository" ]] || die "checkout origin differs from $repository; select its repository or another --repo-dir"
  [[ -z "$revision" ]] || die '--ref only applies to a new checkout; switch the existing checkout with Git first'
else
  mkdir -p -- "$(dirname -- "$repo_dir")"
  if [[ -z "$revision" ]]; then
    git clone --depth 1 -- "https://github.com/$repository.git" "$repo_dir"
  else
    git clone -- "https://github.com/$repository.git" "$repo_dir"
    git -C "$repo_dir" checkout "$revision"
  fi
fi
[[ -f "$repo_dir/flake.nix" && -f "$repo_dir/flake.lock" && -f "$repo_dir/nixos/profile.nix" ]] || die 'checkout needs the root flake and nixos/profile.nix; update the checkout with Git first'
flake="path:$repo_dir"
# A new flake input requires a lock entry before any --no-write-lock-file eval.
# Only refresh automatically on first migration; normal updates remain explicit.
if ! jq -e '.nodes.root.inputs["nix-cachyos-kernel"]' "$repo_dir/flake.lock" >/dev/null; then
  nix "${nixflags[@]}" flake lock --flake "$flake"
fi
bash "$repo_dir/scripts/copy-hardware.sh" "$repo_dir" --if-missing
# Capture the installed system once. Later updates retain these stateful defaults.
if [[ ! -s "$repo_dir/nixos/local-system.json" ]]; then
  temporary=$(mktemp "$repo_dir/nixos/.local-system.XXXXXXXX")
  trap 'rm -f -- "$temporary"' EXIT
  CONFIG_FLAKE="$flake" CONFIG_USER="$username" CONFIG_HOST="$(uname -n)" \
    nix "${nixflags[@]}" eval --impure --json --no-write-lock-file --expr '
      let f = builtins.getFlake (builtins.getEnv "CONFIG_FLAKE");
      in import (f.outPath + "/scripts/installed-system.nix") {
        nixpkgs = f.inputs.nixpkgs;
        username = builtins.getEnv "CONFIG_USER";
        hostName = builtins.getEnv "CONFIG_HOST";
      }' > "$temporary"
  jq -e '.stateVersion and .bootLoader' "$temporary" >/dev/null || die 'could not read installed bootloader/state version'
  chmod 600 "$temporary"
  mv -fT -- "$temporary" "$repo_dir/nixos/local-system.json"
fi
if [[ -z "$hardware" ]]; then
  if [[ -f "$repo_dir/nixos/local-profile.nix" ]] && [[ $(<"$repo_dir/nixos/local-profile.nix") == *hardwareProfile* ]]; then
    hardware=$(nix "${nixflags[@]}" eval --raw --no-write-lock-file "$flake#lib.deployment.hardwareProfile")
  elif [[ -r /sys/class/dmi/id/product_name ]] && [[ $(</sys/class/dmi/id/product_name) == *FA401* ]]; then
    hardware=asus-tuf-a14
  else
    hardware=generic
  fi
fi
if [[ -z "$host" && -f "$repo_dir/nixos/local-profile.nix" ]]; then
  host=$(nix "${nixflags[@]}" eval --raw --no-write-lock-file "$flake#lib.deployment.hostName")
fi
# JSON strings become Nix strings after escaping Nix interpolation.
nix_string() { jq -nr --arg value "$1" '$value | tojson | gsub("\\$\\{"; "\\${")'; }
temporary=$(mktemp "$repo_dir/nixos/.local-profile.XXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
{
  printf '# Generated by config-apply; personal defaults remain in profile.nix.\n{\n'
  printf '  username = %s;\n' "$(nix_string "$username")"
  printf '  homeDirectory = %s;\n' "$(nix_string "$HOME")"
  printf '  configRepo = %s;\n' "$(nix_string "$repo_dir")"
  # Add the personal data disk only on a machine that actually has it.
  if [[ -e /dev/disk/by-uuid/71d4d606-a6ef-42bb-b63c-8f5a8fee4b24 ]]; then
    printf '  storageUUID = "71d4d606-a6ef-42bb-b63c-8f5a8fee4b24";\n'
  fi
  printf '  system = "x86_64-linux";\n'
  printf '  hardwareProfile = %s;\n' "$(nix_string "$hardware")"
  [[ -z "$host" ]] || printf '  hostName = %s;\n' "$(nix_string "$host")"
  printf '}\n'
} > "$temporary"
chmod 600 "$temporary"
mv -fT -- "$temporary" "$repo_dir/nixos/local-profile.nix"
if [[ "$update_inputs" == true ]]; then nix "${nixflags[@]}" flake update --flake "$flake"; fi
[[ -n "$host" ]] || host=$(nix "${nixflags[@]}" eval --no-write-lock-file --raw "$flake#lib.deployment.hostName")
[[ "$host" =~ ^[A-Za-z0-9_-]+$ ]] || die 'invalid configured host name'
target="$flake#nixosConfigurations.$host.config.system.build.toplevel"
printf 'Building NixOS system %s for %s...\n' "$host" "$username"
if [[ "$build_only" == true ]]; then
  nix "${nixflags[@]}" build --no-write-lock-file --no-link "$target"
  printf 'Build succeeded. Nothing activated.\n'
else
  command -v sudo >/dev/null || die 'sudo is required to activate NixOS'
  # nixos-rebuild builds before switching; no separate pre-build is needed.
  sudo nixos-rebuild switch --flake "$flake#$host" --option experimental-features 'nix-command flakes' --no-write-lock-file
fi
printf 'Checkout: %s\n' "$repo_dir"
