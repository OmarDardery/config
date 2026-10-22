#!/usr/bin/env bash
# Run from the repository root with bash nixos/tests/bootstrap.sh. No Nix builds or real activation are allowed.
# Literal shell expressions below are test seams, not expanded test variables.
# shellcheck disable=SC2016
set -euo pipefail

root=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd)
bash_bin=$(command -v bash)
env_bin=$(command -v env)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/checkout/nixos" "$tmp/store/output" "$tmp/retention"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# [[ ... ]] is shell syntax, not a mockable command. These two explicit seams
# select the OS and redirect the store-directory check to a disposable fixture.
# All other production code runs unchanged, in a fresh shell for each case.
source_text=$(<"$root/bootstrap.sh")
os_check='[[ -e /etc/NIXOS ]]'
store_check='"$output" == /nix/store/*'
remaining=${source_text#*"$os_check"}
[[ "$remaining" != "$source_text" ]] || fail 'missing first OS seam'
remaining=${remaining#*"$os_check"}
[[ "$remaining" != *"$os_check"* ]] || fail 'unexpected extra OS seam'
[[ "$source_text" == *"$os_check"*"$os_check"* ]] || fail 'missing second OS seam'
[[ "$source_text" == *"$store_check"* ]] || fail 'missing store seam'
remaining=${source_text#*"$store_check"}
[[ "$remaining" != *"$store_check"* ]] || fail 'unexpected extra store seam'
source_text=${source_text//"$os_check"/'[[ "$MOCK_OS" == nixos ]]'}
source_text=${source_text//"$store_check"/'"$output" == "$MOCK_STORE/"*'}
printf '%s\n' "$source_text" > "$tmp/bootstrap.sh"

# Only these executables are visible to the child. Unexpected calls fail closed;
# in particular git and privilege/activation commands never reach the real host.
printf '#!%s\n' "$bash_bin" > "$tmp/bin/mock"
IFS= read -r -d '' mock_text <<'MOCK' || true
set -euo pipefail
name=${0##*/}
[[ "$name" == activate || -z "${HOME_MANAGER_BACKUP_EXT+x}" ]] || exit 90
printf '%s' "$name" >> "$MOCK_LOG"
printf ' %q' "$@" >> "$MOCK_LOG"
printf '\n' >> "$MOCK_LOG"
case "$name" in
  id)
    case "$*" in
      -u) printf '%s\n' "$MOCK_UID" ;;
      -un) printf '%s\n' "$MOCK_USER" ;;
      *) exit 90 ;;
    esac ;;
  uname)
    case "$*" in
      -s) printf 'Linux\n' ;;
      -m) printf '%s\n' "$MOCK_ARCH" ;;
      *) exit 90 ;;
    esac ;;
  findmnt)
    [[ $# == 6 && "$1 $2 $3 $5" == '--noheadings --raw --mountpoint --output' ]] || exit 90
    case "$4:$6" in
      /:UUID) printf '%s\n' "$MOCK_UUID" ;;
      /boot:UUID) printf 'boot-uuid\n' ;;
      /:FSTYPE) printf '%s\n' "$MOCK_ROOT_TYPE" ;;
      /boot:FSTYPE) printf '%s\n' "$MOCK_BOOT_TYPE" ;;
      *) exit 90 ;;
    esac ;;
  nix)
    [[ $# -ge 3 && "$1" == --extra-experimental-features && "$2" == 'nix-command flakes' ]] || exit 90
    shift 2
    case "$1" in
      eval)
        [[ $# == 4 && "$2 $3" == '--no-write-lock-file --raw' ]] || exit 90
        case "$4" in
          "$MOCK_FLAKE#lib.deployment.profileName") printf '%s\n' "$MOCK_DEFAULT_PROFILE" ;;
          "$MOCK_FLAKE#lib.deployment.hostName") printf '%s\n' "$MOCK_DEFAULT_HOST" ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.pkgs.stdenv.hostPlatform.system"|\
          "$MOCK_FLAKE#homeConfigurations.$MOCK_PROFILE.pkgs.stdenv.hostPlatform.system")
            printf '%s\n' "$MOCK_SYSTEM" ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.home-manager.users.\"$MOCK_USER\".home.username")
            [[ "$MOCK_HM_ENTRY" == present ]] || exit 90
            printf '%s\n' "$MOCK_PROFILE_USER" ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.home-manager.users.\"$MOCK_USER\".home.sessionVariables.NH_FLAKE"|\
          "$MOCK_FLAKE#homeConfigurations.$MOCK_PROFILE.config.home.sessionVariables.NH_FLAKE")
            printf '%s\n' "$MOCK_CONFIGURED_FLAKE" ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.fileSystems.\"/\".fsType")
            printf 'xfs\n' ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.fileSystems.\"/boot\".fsType")
            printf 'vfat\n' ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.fileSystems.\"/\".device")
            printf '/dev/disk/by-uuid/%s\n' "$MOCK_DEVICE_UUID" ;;
          "$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.fileSystems.\"/boot\".device")
            printf '/dev/disk/by-uuid/boot-uuid\n' ;;
          "$MOCK_FLAKE#homeConfigurations.$MOCK_PROFILE.config.home.username")
            printf '%s\n' "$MOCK_PROFILE_USER" ;;
          "$MOCK_FLAKE#homeConfigurations.$MOCK_PROFILE.config.home.homeDirectory")
            printf '%s\n' "$MOCK_PROFILE_HOME" ;;
          *) exit 90 ;;
        esac ;;
      build)
        [[ $# == 6 && "$2 $3 $5" == '--no-write-lock-file --out-link --print-out-paths' ]] || exit 90
        [[ "$4" == "$TMPDIR"/configs-bootstrap.*/result && -d "${4%/*}" ]] || exit 90
        case "$MOCK_OS:$6" in
          "nixos:$MOCK_FLAKE#nixosConfigurations.$MOCK_HOST.config.system.build.toplevel"|\
          "linux:$MOCK_FLAKE#homeConfigurations.$MOCK_PROFILE.activationPackage") ;;
          *) exit 90 ;;
        esac
        [[ "$MOCK_BUILD" != fail ]] || exit 42
        ln -s "$MOCK_OUTPUT" "$4"
        printf '%s\n' "$MOCK_OUTPUT" ;;
      *) exit 90 ;;
    esac ;;
  activate)
    [[ $# == 0 && "$MOCK_OS" == linux ]] || exit 90
    roots=("$TMPDIR"/configs-bootstrap.*/result)
    [[ ${#roots[@]} == 1 && -L "${roots[0]}" && -d "${roots[0]}" ]] || exit 90
    [[ "${HOME_MANAGER_BACKUP_EXT-}" == "$MOCK_BACKUP_EXTENSION" ]] || exit 90
    [[ -n "$MOCK_BACKUP_EXTENSION" || -z "${HOME_MANAGER_BACKUP_EXT+x}" ]] || exit 90 ;;
  sudo)
    [[ "${MOCK_ALLOW_SWITCH:-}" == yes ]] || exit 90
    "$@" ;;
  nix-env|switch-to-configuration)
    [[ "${MOCK_ALLOW_SWITCH:-}" == yes ]] || exit 90
    roots=("$TMPDIR"/configs-bootstrap.*/result)
    [[ ${#roots[@]} == 1 && -L "${roots[0]}" && -d "${roots[0]}" ]] || exit 90
    if [[ "$name" == nix-env ]]; then
      [[ "$*" == "--profile /nix/var/nix/profiles/system --set $MOCK_STORE/output" ]] || exit 90
    else
      [[ "$*" == switch ]] || exit 90
      [[ "${MOCK_SWITCH_FAIL:-}" != yes ]] || exit 42
    fi ;;
  git) exit 90 ;;
  *) exit 90 ;;
esac
MOCK
printf '%s\n' "$mock_text" >> "$tmp/bin/mock"
chmod +x "$tmp/bin/mock"
for command in id uname findmnt nix git sudo nix-env; do
  ln -s mock "$tmp/bin/$command"
done
for command in realpath mktemp rm ln; do
  ln -s "$(command -v "$command")" "$tmp/bin/$command"
done
ln -s "$tmp/bin/mock" "$tmp/store/output/activate"
mkdir -p "$tmp/store/output/bin"
ln -s "$tmp/bin/mock" "$tmp/store/output/bin/switch-to-configuration"

# A real, local dirty index and untracked file ensure preservation assertions
# cover more than command logs. No network, commits, or user git config changes.
printf 'staged flake\n' > "$tmp/checkout/nixos/flake.nix"
printf '{}\n' > "$tmp/checkout/nixos/flake.lock"
git -C "$tmp/checkout" init -q
git -C "$tmp/checkout" add nixos/flake.nix
printf 'dirty flake\n' > "$tmp/checkout/nixos/flake.nix"
printf 'untracked module\n' > "$tmp/checkout/nixos/local.nix"
git -C "$tmp/checkout" status --porcelain=v1 > "$tmp/status.before"
git -C "$tmp/checkout" diff --cached --binary > "$tmp/index.before"
git -C "$tmp/checkout" diff --binary > "$tmp/diff.before"
cp "$tmp/checkout/nixos/local.nix" "$tmp/untracked.before"
cp "$tmp/checkout/nixos/flake.lock" "$tmp/lock.before"

reset_case() {
  repo_args=(--repo-dir "$tmp/checkout")
  os=linux uid=1000 user=fixture uuid=root-uuid device_uuid=root-uuid
  arch=x86_64 system=x86_64-linux root_type=xfs boot_type=vfat hm_entry=present
  configured_flake="$tmp/checkout/nixos"
  profile_user=fixture profile_home="$tmp/home"
  build=ok output="$tmp/store/output"
  default_profile=oad default_host=nixos selected_profile=oad selected_host=nixos
  backup_extension=
  : > "$tmp/log"
}

run_case() {
  local expected=$1 label=$2 status=0
  shift 2
  "$env_bin" -i PATH="$tmp/bin" HOME="$tmp/home" TMPDIR="$tmp/retention" \
    MOCK_OS="$os" MOCK_UID="$uid" MOCK_USER="$user" \
    MOCK_UUID="$uuid" MOCK_DEVICE_UUID="$device_uuid" \
    MOCK_ARCH="$arch" MOCK_SYSTEM="$system" MOCK_ROOT_TYPE="$root_type" MOCK_BOOT_TYPE="$boot_type" \
    MOCK_HM_ENTRY="$hm_entry" MOCK_CONFIGURED_FLAKE="$configured_flake" \
    MOCK_PROFILE_USER="$profile_user" MOCK_PROFILE_HOME="$profile_home" \
    MOCK_DEFAULT_PROFILE="$default_profile" MOCK_DEFAULT_HOST="$default_host" \
    MOCK_PROFILE="$selected_profile" MOCK_HOST="$selected_host" MOCK_BACKUP_EXTENSION="$backup_extension" \
    MOCK_BUILD="$build" MOCK_OUTPUT="$output" MOCK_STORE="$tmp/store" \
    MOCK_FLAKE="path:$tmp/checkout/nixos" MOCK_LOG="$tmp/log" \
    "$bash_bin" --noprofile --norc "$tmp/bootstrap.sh" \
    "${repo_args[@]}" "$@" > "$tmp/stdout" 2> "$tmp/stderr" || status=$?
  if [[ "$expected" == pass ]]; then
    [[ "$status" == 0 ]] || fail "$label: unexpected exit $status: $(<"$tmp/stderr")"
  else
    [[ "$status" != 0 ]] || fail "$label: unexpectedly succeeded"
    [[ "$expected" == fail || "$(<"$tmp/stderr")" == *"$expected"* ]] || fail "$label: wrong refusal: $(<"$tmp/stderr")"
  fi
  local leftovers=("$tmp/retention"/configs-bootstrap.*)
  [[ ! -e "${leftovers[0]}" ]] || fail "$label: build root was not cleaned up"
  local log
  log=$(<"$tmp/log")
  [[ "$log" != *git* && "$log" != *sudo* && "$log" != *nix-env* ]] || fail "$label: forbidden command"
  [[ "$log" != *activate* || "$expected" == pass && " $* " == *' --activate '* ]] || fail "$label: unexpected activation"
  cases=$((cases + 1))
  printf 'PASS: %s\n' "$label"
}

no_build() {
  [[ "$(<"$tmp/log")" != *'nix --extra-experimental-features nix-command\ flakes build '* ]] || fail 'refusal reached build'
}

cases=0
for os_case in nixos linux; do
  for mode in default explicit; do
    reset_case
    os=$os_case
    args=()
    [[ "$mode" != explicit ]] || args=(--build-only)
    run_case pass "$os build-only ($mode)" "${args[@]}"
    [[ "$(<"$tmp/stdout")" == *'Nothing was activated.'* ]] || fail 'missing build-only message'
    [[ "$(<"$tmp/log")" == *'--no-write-lock-file --out-link'* ]] || fail 'build was not called'
  done
done

for os_case in nixos linux; do
  reset_case; os=$os_case
  default_profile=work-user default_host=work-host
  selected_profile=$default_profile selected_host=$default_host
  run_case pass "$os profile.nix-derived selectors"
  log=$(<"$tmp/log")
  [[ "$log" == *'#lib.deployment.profileName'* && "$log" == *'#lib.deployment.hostName'* ]] || fail 'missing deployment metadata queries'

  reset_case; os=$os_case
  default_profile='invalid/default' default_host='invalid/default'
  selected_profile=chosen-user selected_host=chosen-host
  run_case pass "$os explicit selectors skip defaults" --profile "$selected_profile" --host "$selected_host"
  [[ "$(<"$tmp/log")" != *'#lib.deployment.'* ]] || fail 'explicit selectors queried defaults'
done
reset_case
ln -s "$tmp/checkout" "$tmp/home/config"
repo_args=()
run_case pass 'default checkout is ~/config' --build-only

reset_case; default_profile='invalid/default'; selected_profile=chosen-user
run_case pass 'explicit profile skips only profile default' --profile "$selected_profile"
log=$(<"$tmp/log")
[[ "$log" != *'#lib.deployment.profileName'* && "$log" == *'#lib.deployment.hostName'* ]] || fail 'incorrect partial profile default queries'
reset_case; os=nixos; default_host='invalid/default'; selected_host=chosen-host
run_case pass 'explicit host skips only host default' --host "$selected_host"
log=$(<"$tmp/log")
[[ "$log" == *'#lib.deployment.profileName'* && "$log" != *'#lib.deployment.hostName'* ]] || fail 'incorrect partial host default queries'

for field in profile host; do
  for value in '' 'bad/name' 'bad#name' 'bad?name' 'bad.name' 'bad name' $'bad\nname'; do
    reset_case
    if [[ "$field" == profile ]]; then default_profile=$value; else default_host=$value; fi
    run_case "invalid $field name in profile.nix" "invalid metadata $field: $(printf '%q' "$value")"; no_build
    [[ "$(<"$tmp/log")" != *'.pkgs.stdenv.hostPlatform.system'* ]] || fail 'invalid metadata reached configuration query'
    [[ "$(<"$tmp/stderr")" != *"$tmp/home"* && "$(<"$tmp/stderr")" != *"$tmp/checkout"* ]] || fail 'invalid metadata leaked home or checkout path'
  done
  reset_case
  run_case "invalid $field name" "invalid explicit $field selector" "--$field" 'bad/name'; no_build
done

reset_case; uid=0
run_case 'not root' 'root refusal'; no_build
for os_case in nixos linux; do
  reset_case; os=$os_case; arch=aarch64
  run_case 'Unsupported profile architecture' "$os architecture refusal"; no_build
  reset_case; os=$os_case; system=aarch64-linux
  run_case 'requires aarch64-linux' "$os evaluated architecture refusal"; no_build
  reset_case; os=$os_case; configured_flake=/home/oad/config/nixos
  run_case pass "$os custom repository only warns"
  [[ "$(<"$tmp/stderr")" == *'Edit profile.configRepo in '*'/profile.nix'* ]] || fail 'missing follow-up repository warning'
done
reset_case; os=nixos; hm_entry=missing
run_case 'No configured Home Manager entry' 'NixOS missing user entry'; no_build
reset_case; os=nixos; profile_user=oad
run_case 'requires user oad' 'NixOS user mismatch'; no_build
reset_case; os=nixos; root_type=ext4
run_case 'Filesystem type mismatch for /:' 'root filesystem mismatch'; no_build
reset_case; os=nixos; boot_type=ext4
run_case 'Filesystem type mismatch for /boot:' 'boot filesystem mismatch'; no_build
reset_case; os=nixos; root_type=''
run_case 'mounted unknown' 'empty filesystem type'; no_build
reset_case
run_case pass 'portable tools build without desktop services'
[[ "$(<"$tmp/stdout")" == *'applications and desktop services are installed separately'* ]] || fail 'missing portable profile description'
reset_case; os=nixos; uuid=''
run_case 'Missing or invalid UUID' 'empty UUID refusal'; no_build
reset_case; os=nixos; device_uuid=other-uuid
run_case 'Hardware mismatch' 'root UUID mismatch refusal'; no_build
reset_case; profile_user=other-user
run_case 'requires user other-user' 'profile user mismatch'; no_build
reset_case; profile_home=/wrong-home
run_case 'HOME=/wrong-home' 'profile home mismatch'; no_build
reset_case; build=fail
run_case fail 'failed build cannot activate' --activate
reset_case; output="$tmp/not-a-store-output"
run_case 'single store output' 'invalid output cannot activate' --activate
reset_case
run_case pass 'Home Manager builds before activation without sudo' --activate
log=$(<"$tmp/log")
[[ "$log" == *'--no-write-lock-file --out-link'*$'\nactivate '* ]] || fail 'activation did not follow build'
[[ "$(<"$tmp/stdout")" == *'Activation completed'* ]] || fail 'activation did not complete'

reset_case; backup_extension=bootstrap-backup
run_case pass 'standalone activation scopes backup extension to exact closure' --activate --backup-extension "$backup_extension"
[[ "$(<"$tmp/log")" == *'--no-write-lock-file --out-link'*$'\nactivate '* ]] || fail 'backup activation did not follow build'
reset_case
run_case 'requires standalone --activate' 'backup extension requires activation' --backup-extension backup; no_build
reset_case; os=nixos
run_case 'only supported for standalone --activate' 'NixOS refuses backup extension' --activate --backup-extension backup; no_build
for value in '' 'bad/name' 'bad#name' 'bad?name' 'bad name' $'bad\nname'; do
  reset_case
  run_case fail "invalid backup extension: $(printf '%q' "$value")" --activate --backup-extension "$value"; no_build
  [[ "$(<"$tmp/stderr")" != *"$tmp/home"* && "$(<"$tmp/stderr")" != *"$tmp/checkout"* ]] || fail 'invalid backup extension leaked home or checkout path'
done
reset_case; backup_extension=backup; build=fail
run_case fail 'failed build with backup cannot activate' --activate --backup-extension "$backup_extension"

python3 "$root/tests/bootstrap-retention.py" "$tmp" "$bash_bin"

git -C "$tmp/checkout" status --porcelain=v1 > "$tmp/status.after"
git -C "$tmp/checkout" diff --cached --binary > "$tmp/index.after"
git -C "$tmp/checkout" diff --binary > "$tmp/diff.after"
cmp "$tmp/status.before" "$tmp/status.after"
cmp "$tmp/index.before" "$tmp/index.after"
cmp "$tmp/diff.before" "$tmp/diff.after"
cmp "$tmp/untracked.before" "$tmp/checkout/nixos/local.nix"
cmp "$tmp/lock.before" "$tmp/checkout/nixos/flake.lock"
[[ ! -e "$tmp/checkout/result" ]] || fail 'result symlink created'
printf 'PASS: dirty checkout, index, untracked files, and lock preserved\n'
printf 'All %s mocked bootstrap cases and 6 checkout preservation assertions passed.\n' "$cases"
