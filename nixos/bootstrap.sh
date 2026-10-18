#!/usr/bin/env bash
# Build the NixOS host or standalone Home Manager profile before activation.
set -euo pipefail

REPO_HTTPS="https://github.com/OmarDardery/config.git"
repo_dir="${HOME:?HOME must be set}/configs"
profile=
host=
backup_extension=
activate=false
install_nix=false
mode_selected=false
setup_host=false
apply_host=false
deployment_options=false
nixflags=(--extra-experimental-features "nix-command flakes")

say() { printf '\n== %s\n' "$1"; }
warn() { printf 'Warning: %s\n' "$1" >&2; }
die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

usage() {
  printf '%s\n' \
    'Usage: bash nixos/bootstrap.sh [OPTIONS]' \
    '' \
    'Linux only; run as your normal user, never root.' \
    'NixOS builds nixosConfigurations.<host>; other Linux builds Home Manager.' \
    '' \
    '  --repo-dir DIR  Existing checkout or new clone destination (default: ~/configs)' \
    '  --profile NAME Standalone named profile (default: profile.nix profileName)' \
    '  --host NAME    NixOS flake host (default: profile.nix hostName)' \
    '  --build-only   Build without activation (default)' \
    '  --activate     Build first, then activate; NixOS also asks for confirmation' \
    '  --backup-extension EXT  Back up conflicting files for standalone --activate' \
    '                          EXT uses only letters, digits, dots, underscores or hyphens.' \
    '  --install-nix  Show official installation instructions if Nix is missing' \
    '                 No installer is downloaded or executed by this script.' \
    '  --setup-host   Preview minimal native Fedora/Debian prerequisites; no Nix needed' \
    '  --apply-host   Requires --setup-host; confirm each sudo command on a terminal' \
    '                 Host setup cannot be combined with deployment options.' \
    '                 --repo-dir is allowed but ignored; no clone/build/activation.' \
    '  -h, --help     Show this help' \
    '' \
    'Existing checkouts are never pulled, staged, or reset.' \
    'Builds use path:<repo>/nixos, include untracked files, and never write locks.' \
    'Deployment identity and defaults are explicit in nixos/profile.nix.' \
    'For another user, edit profile.nix; selectors do not infer identity from the environment.' \
    'Hardware files and /etc/nixos are never overwritten or linked.'
}

while (($#)); do
  case "$1" in
    --repo-dir | --profile | --host | --backup-extension)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] ||
        die "$1 requires a value"
      case "$1" in
        --repo-dir) repo_dir=$2 ;;
        --profile)
          profile=$2
          deployment_options=true
          ;;
        --host)
          host=$2
          deployment_options=true
          ;;
        --backup-extension)
          backup_extension=$2
          deployment_options=true
          ;;
      esac
      shift 2
      ;;
    --build-only | --activate)
      [[ "$mode_selected" == false ]] || die "choose only one activation mode"
      mode_selected=true
      [[ "$1" != --activate ]] || activate=true
      shift
      ;;
    --install-nix)
      install_nix=true
      deployment_options=true
      shift
      ;;
    --setup-host)
      setup_host=true
      shift
      ;;
    --apply-host)
      apply_host=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

[[ $(id -u) != 0 ]] || die 'run as your normal user, not root or through sudo'
[[ $(uname -s) == Linux ]] || die 'only NixOS and non-NixOS Linux are supported'
[[ "$apply_host" == false || "$setup_host" == true ]] || die '--apply-host requires --setup-host'
if [[ "$setup_host" == true ]]; then
  [[ "$mode_selected" == false && "$deployment_options" == false ]] ||
    die '--setup-host is exclusive with activation, build-only, selectors, backup and install-nix options'
  # Dispatch before checking Nix or touching the checkout. Only this explicit path
  # may install native packages; normal builds and activation never call it.
  host_script_dir=${BASH_SOURCE[0]%/*}
  [[ "$host_script_dir" != "${BASH_SOURCE[0]}" ]] || host_script_dir=.
  source "$host_script_dir/bootstrap-host.sh"
  host_setup "$apply_host"
  exit 0
fi
[[ -z "$profile" || "$profile" =~ ^[a-zA-Z0-9_-]+$ ]] || die 'invalid profile name'
[[ -z "$host" || "$host" =~ ^[a-zA-Z0-9_-]+$ ]] || die 'invalid host name'
if [[ -n "$backup_extension" ]]; then
  [[ "$backup_extension" =~ ^[a-zA-Z0-9._-]+$ ]] || die 'invalid backup extension: use only letters, digits, dots, underscores or hyphens'
  [[ "$activate" == true ]] || die '--backup-extension requires standalone --activate'
fi

if ! command -v nix >/dev/null 2>&1; then
  if [[ "$install_nix" == true ]]; then
    printf '%s\n' \
      'Install Nix following https://nixos.org/download/#nix-install-linux' \
      'Review the official installer before running it interactively.' \
      'Choose the documented multi-user installation for your system when supported.' \
      'Then open a new login shell and rerun this script.'
    exit 1
  fi
  die 'Nix is missing or not on PATH. Open a Nix-enabled shell, or use --install-nix for instructions.'
fi

command -v realpath >/dev/null 2>&1 || die 'realpath (coreutils) is required'
repo_dir=$(realpath -m -- "$repo_dir")
# A path flake reference uses these characters as URL delimiters.
[[ "$repo_dir" != *[\?#]* ]] || die 'repository path cannot contain ? or #'
if [[ -e "$repo_dir" || -L "$repo_dir" ]]; then
  [[ -d "$repo_dir" && -f "$repo_dir/nixos/flake.nix" ]] ||
    die "$repo_dir exists but is not a configs checkout; choose --repo-dir"
  say "Using existing $repo_dir without pulling or staging any changes"
else
  command -v git >/dev/null 2>&1 || die 'git is required to clone; install it using your distribution tools'
  [[ -d $(dirname -- "$repo_dir") ]] || die 'clone destination parent must already exist'
  say "Cloning into $repo_dir"
  git clone -- "$REPO_HTTPS" "$repo_dir"
fi

flake_dir="$repo_dir/nixos"
[[ -f "$flake_dir/flake.lock" ]] ||
  die "Missing $flake_dir/flake.lock. Review and create the lock explicitly with nix flake lock before retrying."
flake="path:$flake_dir"
evalflags=(--no-write-lock-file)

if [[ -z "$profile" ]]; then
  profile=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$flake#lib.deployment.profileName")
fi
if [[ -z "$host" ]]; then
  host=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$flake#lib.deployment.hostName")
fi
[[ "$profile" =~ ^[a-zA-Z0-9_-]+$ ]] || die 'invalid profile name in profile.nix'
[[ "$host" =~ ^[a-zA-Z0-9_-]+$ ]] || die 'invalid host name in profile.nix'

if [[ -e /etc/NIXOS ]]; then
  target="$flake#nixosConfigurations.$host.config"
  platform_target="$flake#nixosConfigurations.$host.pkgs.stdenv.hostPlatform.system"
  home_target="$target.home-manager.users.\"$(id -un)\""
else
  target="$flake#homeConfigurations.$profile"
  platform_target="$target.pkgs.stdenv.hostPlatform.system"
  home_target="$target.config"
fi

expected_system=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$platform_target")
actual_system="$(uname -m)-linux"
[[ "$actual_system" == "$expected_system" ]] || die \
  "Unsupported profile architecture: $target requires $expected_system; this machine is $actual_system. Select or adapt a profile for this architecture before building."

if [[ "$target" == "$flake#nixosConfigurations."* ]]; then
  [[ -z "$backup_extension" ]] || die '--backup-extension is only supported for standalone --activate'
  configured_user=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$home_target.home.username") ||
    die "No configured Home Manager entry for current user $(id -un). Edit the explicit deployment identity in $flake_dir/profile.nix before retrying."
  [[ "$configured_user" == "$(id -un)" ]] || die \
    "Configured Home Manager entry requires user $configured_user; current user is $(id -un). Edit the explicit deployment identity in $flake_dir/profile.nix before retrying."
  command -v findmnt >/dev/null 2>&1 || die 'findmnt (util-linux) is required to validate hardware'
  say 'Checking configured root and boot devices and filesystem types against mounted disks'
  for mount in / /boot; do
    uuid=$(findmnt --noheadings --raw --mountpoint "$mount" --output UUID) ||
      die "Cannot identify $mount. Mount the correct filesystem before retrying."
    [[ -n "$uuid" && "$uuid" =~ ^[a-zA-Z0-9-]+$ ]] ||
      die "Missing or invalid UUID for $mount; hardware compatibility cannot be verified."
    device=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw \
      "$target.fileSystems.\"$mount\".device")
    [[ "$device" == "/dev/disk/by-uuid/$uuid" ]] || die \
      "Hardware mismatch for $mount: configured $device, mounted UUID $uuid.
Generate hardware configuration for review with: sudo nixos-generate-config --show-hardware-config
Manually adapt $flake_dir/hardware-configuration.nix and hardware.nix (including storage and GPU/PRIME settings), then retry. No hardware files were overwritten."
    mounted_type=$(findmnt --noheadings --raw --mountpoint "$mount" --output FSTYPE) ||
      die "Cannot identify filesystem type for $mount. Mount the correct filesystem before retrying."
    configured_type=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw \
      "$target.fileSystems.\"$mount\".fsType")
    [[ -n "$mounted_type" && "$mounted_type" == "$configured_type" ]] || die \
      "Filesystem type mismatch for $mount: configured $configured_type, mounted ${mounted_type:-unknown}. Review hardware-configuration.nix and hardware.nix before retrying. No hardware files were overwritten."
  done
  warn 'Disk UUIDs match, but this host has laptop-specific CPU, GPU/PRIME, boot and storage settings. Review hardware.nix and hardware-configuration.nix; arbitrary hardware is not supported automatically.'
  build_target="$target.system.build.toplevel"
else
  say "Checking identity for standalone profile $profile"
  configured_user=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$target.config.home.username")
  configured_home=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$target.config.home.homeDirectory")
  [[ "$configured_user" == "$(id -un)" && "$configured_home" == "$HOME" ]] || die \
    "Profile $profile requires user $configured_user with HOME=$configured_home; current user is $(id -un) with HOME=$HOME. Edit the explicit deployment identity in $flake_dir/profile.nix, or select an existing named profile with --profile."
  warn 'Home Manager supplies user applications, Flatpak CLI/user installations and user services. Review native BlueZ/Bluetooth, systemd/PAM, Wayland session registration, graphics drivers, polkit, keyring, audio, Docker, user namespaces and udev requirements. Fedora/Debian can preview baseline prerequisites with --setup-host.'
  if ! command -v systemctl >/dev/null 2>&1 || ! systemctl --user show-environment >/dev/null 2>&1; then
    warn 'A working host systemd user manager was not detected. Review your distribution login/session setup before relying on Home Manager user services.'
  fi
  warn 'Activation may change managed home files and run profile activation hooks; existing conflicting files are not force-overwritten by this script.'
  build_target="$target.activationPackage"
fi

configured_flake=$(nix "${nixflags[@]}" eval "${evalflags[@]}" --raw "$home_target.programs.nh.flake")
configured_flake=${configured_flake#path:}
if [[ "$flake_dir" != "$configured_flake" ]]; then
  warn "This checkout uses $flake_dir, but programs.nh.flake points to $configured_flake for follow-up commands. Edit profile.configRepo in $flake_dir/profile.nix to this checkout before using nh or configured update commands. This build still uses $flake_dir; no files or persistent environment settings were changed."
fi

say "Building $build_target (no activation yet)"
# Nix registers the out-link as a GC root when the build completes. Keep it
# until activation registers its generation, including time spent at the prompt.
# Nothing is linked inside the checkout; failures and cancellation clean up too.
build_retention=$(mktemp -d "${TMPDIR:-/tmp}/configs-bootstrap.XXXXXXXX")
trap 'rm -rf -- "$build_retention"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
build_root="$build_retention/result"
output=$(nix "${nixflags[@]}" build --no-write-lock-file --out-link "$build_root" --print-out-paths "$build_target")
[[ "$output" == /nix/store/* && "$output" != *$'\n'* && -d "$output" ]] ||
  die 'build did not return a single store output'
say "Build succeeded: $output"
if [[ "$activate" == false ]]; then
  printf '%s\n' 'Nothing was activated. Rerun with --activate when ready.'
  exit 0
fi

if [[ -e /etc/NIXOS ]]; then
  command -v sudo >/dev/null 2>&1 || die 'sudo is required for NixOS activation'
  command -v nix-env >/dev/null 2>&1 || die 'nix-env is required to register the NixOS generation'
  [[ -x "$output/bin/switch-to-configuration" ]] || die 'built output has no NixOS activation executable'
  printf '%s\n' 'Confirm you reviewed hardware settings and want to switch the system to this build.'
  if ! read -r -p 'Activate NixOS now? [y/N] ' reply </dev/tty; then
    die 'interactive terminal required for NixOS activation'
  fi
  [[ "$reply" == y || "$reply" == Y ]] || die 'activation cancelled; nothing was activated'
  # Activate the exact closure just built, rather than reevaluating mutable files.
  sudo nix-env --profile /nix/var/nix/profiles/system --set "$output"
  sudo "$output/bin/switch-to-configuration" switch
else
  [[ -x "$output/activate" ]] || die 'built output has no Home Manager activation executable'
  if [[ -n "$backup_extension" ]]; then
    HOME_MANAGER_BACKUP_EXT="$backup_extension" "$output/activate"
  else
    "$output/activate"
  fi
fi
say 'Activation completed; log out and back in for session changes'
