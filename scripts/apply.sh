#!/usr/bin/env bash
set -euo pipefail
repository=OmarDardery/config
repo_dir="${HOME:?HOME must be set}/config"
revision=
host=
profile=
backup_extension="before-config-$(date +%Y%m%d-%H%M%S)-$$"
build_only=false
home_only=false
repository_selected=false
nixflags=(--extra-experimental-features 'nix-command flakes')
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'HELP'
Usage: nix run github:OmarDardery/config -- [OWNER/REPO] [OPTIONS]
Applies the NixOS system on NixOS, or Home Manager apps/dotfiles on other Linux.
Run as your normal user with Nix installed. No apt/dnf, driver or greeter setup.
  --repo-dir DIR          Checkout location (default: ~/config)
  --ref REF              Git branch, tag or commit for a NEW checkout
  --host NAME            NixOS configuration (default: profile.nix hostName)
  --profile NAME         default, core, dev, gaming, desktop, or full output name
                         (default: last selection, otherwise current username)
  --home                 Apply only Home Manager, even on NixOS
  --build-only           Build without activation
  --backup-extension EXT Backup conflicting dotfiles with this suffix
  -h, --help             Show help
Repository accepts OWNER/REPO, github:OWNER/REPO, or an HTTPS GitHub URL.
Existing checkouts are never pulled, reset or switched; update them with Git.
Generated identity/hardware stay local. Editors and Steam are home-managed;
the desktop session stays distro-managed outside NixOS.
NixOS hardware.nix is specific to the ASUS TUF A14.
HELP
}
while (($#)); do
  case "$1" in
    --repo-dir|--ref|--host|--profile|--backup-extension)
      (($# >= 2)) && [[ -n "$2" && "$2" != -* ]] || die "$1 requires a value"
      case "$1" in
        --repo-dir) repo_dir=$2 ;;
        --ref) revision=$2 ;;
        --host) host=$2 ;;
        --profile) profile=$2 ;;
        --backup-extension) backup_extension=$2 ;;
      esac
      shift 2 ;;
    --home) home_only=true; shift ;;
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
[[ $(uname -s) == Linux ]] || die 'this configuration supports Linux only'
[[ $(uname -m) == x86_64 ]] || die 'this workstation currently supports x86_64-linux only'
command -v nix >/dev/null || die 'install Nix first: https://nixos.org/download/'
repository=${repository#github:}
repository=${repository#https://github.com/}
repository=${repository%/}
repository=${repository%.git}
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'expected a GitHub OWNER/REPO or HTTPS repository URL; use --ref for a branch'
[[ -z "$host" || "$host" =~ ^[A-Za-z0-9_-]+$ ]] || die 'invalid host name'
[[ -z "$profile" || "$profile" =~ ^[A-Za-z0-9_-]+$ ]] || die 'invalid profile name'
[[ "$backup_extension" =~ ^[A-Za-z0-9._-]+$ ]] || die 'invalid backup suffix'
username=$(id -un)
[[ "$username" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || die 'unsupported account name'
repo_dir=$(realpath -m -- "$repo_dir")
[[ "$repo_dir" != *[\?#]* ]] || die 'checkout path cannot contain ? or #'
backend=home
if [[ -e /etc/NIXOS && "$home_only" == false ]]; then backend=os; fi
[[ "$backend" == os || -z "$host" ]] || die '--host requires NixOS system mode'
[[ "$backend" == home || -z "$profile" ]] || die '--profile requires Home Manager mode'
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
  git clone -- "https://github.com/$repository.git" "$repo_dir"
  if [[ -n "$revision" ]]; then git -C "$repo_dir" checkout "$revision"; fi
fi
[[ -f "$repo_dir/flake.nix" && -f "$repo_dir/flake.lock" && -f "$repo_dir/nixos/profile.nix" ]] || die 'checkout needs the root flake and nixos/profile.nix; update the checkout with Git first'
if [[ "$backend" == home ]]; then
  if [[ -z "$profile" && -f "$repo_dir/nixos/local-profile.nix" ]]; then
    profile=$(nix "${nixflags[@]}" eval --raw --file "$repo_dir/nixos/local-profile.nix" --apply 'p: p.profileName or ""')
    [[ "$profile" == "$username" || "$profile" == "$username-"* ]] || profile=
  fi
  case "$profile" in
    ''|default) profile=$username ;;
    core|dev|gaming|desktop) profile="$username-$profile" ;;
  esac
  [[ "$profile" =~ ^[A-Za-z0-9_-]+$ ]] || die 'invalid saved profile name'
fi
# JSON strings become Nix strings after escaping Nix interpolation.
nix_string() { jq -nr --arg value "$1" '$value | tojson | gsub("\\$\\{"; "\\${")'; }
temporary=$(mktemp "$repo_dir/nixos/.local-profile.XXXXXXXX")
trap 'rm -f -- "$temporary"; if [[ -n "${retention:-}" ]]; then rm -rf -- "$retention"; fi' EXIT
{
  printf '# Generated by config-apply; personal defaults remain in profile.nix.\n{\n'
  printf '  username = %s;\n' "$(nix_string "$username")"
  printf '  homeDirectory = %s;\n' "$(nix_string "$HOME")"
  printf '  configRepo = %s;\n' "$(nix_string "$repo_dir")"
  printf '  system = "x86_64-linux";\n'
  [[ -z "$profile" ]] || printf '  profileName = %s;\n' "$(nix_string "$profile")"
  [[ -z "$host" ]] || printf '  hostName = %s;\n' "$(nix_string "$host")"
  printf '}\n'
} > "$temporary"
chmod 600 "$temporary"
mv -fT -- "$temporary" "$repo_dir/nixos/local-profile.nix"
flake="path:$repo_dir"
if [[ "$backend" == os ]]; then bash "$repo_dir/scripts/copy-hardware.sh" "$repo_dir" --if-missing; fi
[[ -n "$host" ]] || host=$(nix "${nixflags[@]}" eval --no-write-lock-file --raw "$flake#lib.deployment.hostName")
[[ -n "$profile" ]] || profile=$username
[[ "$host" =~ ^[A-Za-z0-9_-]+$ ]] || die 'invalid configured host name'
if [[ "$backend" == os ]]; then
  target="$flake#nixosConfigurations.$host.config.system.build.toplevel"
  printf 'Building NixOS system %s for %s...\n' "$host" "$username"
else
  target="$flake#homeConfigurations.$profile.activationPackage"
  printf 'Building Home Manager apps and dotfiles for %s...\n' "$username"
fi
retention=$(mktemp -d "${TMPDIR:-/tmp}/config-apply.XXXXXXXX")
nix "${nixflags[@]}" build --no-write-lock-file --out-link "$retention/result" "$target"
if [[ "$build_only" == true ]]; then
  printf 'Build succeeded. Nothing activated.\n'
elif [[ "$backend" == os ]]; then
  command -v sudo >/dev/null || die 'sudo is required to activate NixOS'
  sudo nixos-rebuild switch --flake "$flake#$host" --no-write-lock-file
else
  [[ -x "$retention/result/activate" ]] || die 'build output has no Home Manager activation executable'
  HOME_MANAGER_BACKUP_EXT="$backup_extension" "$retention/result/activate"
fi
printf 'Checkout: %s\n' "$repo_dir"
