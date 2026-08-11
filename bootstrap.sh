#!/usr/bin/env bash
#
# Bring this config up on a machine that does not have it yet: fetch the repo,
# point /etc/nixos at it, and switch.
#
# Safe to re-run. Everything is checked before anything is changed, and the
# only steps that need sudo are the symlink and the switch, at the very end.
#
#   nix-shell -p git curl --run \
#     'curl -fsSL https://codeberg.org/oadardery/configs/raw/branch/main/bootstrap.sh | bash'
#
# The nix-shell wrapper is there because a minimal NixOS install has neither
# git nor curl. If you already have both, just run the file.

set -euo pipefail

# ── What we are fetching ──────────────────────────────────────────────────
# The remote is Codeberg, not GitHub. Clone over HTTPS: a machine that has
# just been installed has no SSH key yet, so ssh:// fails before it starts.
# The push URL is set to SSH afterwards so that pushing still uses your key.
REPO_HTTPS="https://codeberg.org/oadardery/configs.git"
REPO_SSH="ssh://git@codeberg.org/oadardery/configs.git"

REPO_DIR="$HOME/configurations"
FLAKE_DIR="$REPO_DIR/nixos"   # the flake is in a subdirectory of the repo
HOST="nixos"                  # nixosConfigurations.<this> in flake.nix
OWNER="oad"                   # home/default.nix hardcodes /home/oad

# Flakes are not enabled on a fresh install — nix.settings only lands with the
# first switch — so every nix call here has to turn them on for itself.
nixflags=(--extra-experimental-features "nix-command flakes")

say()  { printf '\n== %s\n' "$1"; }
ok()   { printf '   ok    %s\n' "$1"; }
warn() { printf '   warn  %s\n' "$1"; }
die()  { printf '   FAIL  %s\n' "$1" >&2; exit 1; }

# Read from the terminal, not stdin — stdin is the curl pipe.
confirm() {
  local reply
  read -r -p "   $1 [y/N] " reply < /dev/tty
  [ "$reply" = "y" ] || [ "$reply" = "Y" ]
}

# ── 1. Preflight ──────────────────────────────────────────────────────────
say "Checking this machine"

[ -e /etc/NIXOS ] || die "this is not NixOS"
ok "NixOS $(nixos-version)"

[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root — \$HOME would be /root"
[ "$(id -un)" = "$OWNER" ] || die "this config is written for the user '$OWNER' (home/default.nix), you are '$(id -un)'"
ok "running as $OWNER"

command -v git >/dev/null || die "no git — re-run inside: nix-shell -p git curl"
ok "git present"

curl -fsS -o /dev/null "$REPO_HTTPS/info/refs?service=git-upload-pack" \
  || die "cannot reach $REPO_HTTPS — no network, or the repo moved"
ok "remote reachable"

avail=$(df --output=avail -BG /nix 2>/dev/null | tail -1 | tr -dc '0-9')
if [ "${avail:-0}" -lt 15 ]; then
  warn "only ${avail}G free on /nix — a first build of this closure wants ~15G"
else
  ok "${avail}G free on /nix"
fi

# ── 2. Save the installer's hardware config before /etc/nixos is replaced ──
# hardware-configuration.nix is committed to the repo, but it holds THIS
# laptop's disk UUIDs. On a reinstall or a new disk those change, and the
# committed file would refer to partitions that do not exist. The installer
# already generated a correct one — grab it now, while /etc/nixos is still
# the real directory and not our symlink.
live_hw=""
if [ -f /etc/nixos/hardware-configuration.nix ] && [ ! -L /etc/nixos ]; then
  live_hw=$(mktemp)
  cp /etc/nixos/hardware-configuration.nix "$live_hw"
fi

# ── 3. Get the repo ───────────────────────────────────────────────────────
say "Fetching the config"

if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only \
    || die "$REPO_DIR has local commits or changes — commit, push or stash them first"
  ok "updated $REPO_DIR"
else
  git clone "$REPO_HTTPS" "$REPO_DIR"
  git -C "$REPO_DIR" remote set-url --push origin "$REPO_SSH"
  ok "cloned to $REPO_DIR (pushes go over SSH)"
fi

[ -f "$FLAKE_DIR/flake.nix" ] || die "no flake.nix in $FLAKE_DIR"

# ── 4. Make the hardware match the hardware ───────────────────────────────
say "Checking hardware-configuration.nix against the real disks"

hw="$FLAKE_DIR/hardware-configuration.nix"
root_uuid=$(findmnt -no UUID /)
boot_uuid=$(findmnt -no UUID /boot)

if grep -q "$root_uuid" "$hw" && grep -q "$boot_uuid" "$hw"; then
  ok "root and /boot UUIDs match"
elif [ -n "$live_hw" ]; then
  cp "$live_hw" "$hw"
  warn "UUIDs differed — replaced with the one the installer generated"
  warn "review $hw and commit it, it is now specific to this machine"
else
  die "the committed hardware-configuration.nix is for a different machine.
        Generate one:  sudo nixos-generate-config --show-hardware-config > $hw"
fi

# The second disk is mounted with nofail, so a missing one does not stop the
# boot — but the `lc` alias and anything under /mnt/storage silently break.
storage_uuid=$(grep -A2 '"/mnt/storage"' "$FLAKE_DIR/hardware.nix" | grep -o 'by-uuid/[^"]*' | cut -d/ -f2)
if [ -z "$storage_uuid" ]; then
  ok "no /mnt/storage in this config"
elif [ -e "/dev/disk/by-uuid/$storage_uuid" ]; then
  ok "/mnt/storage disk present"
else
  warn "no disk with UUID $storage_uuid — /mnt/storage will not mount (nofail, so boot is fine)"
  warn "fix the UUID in $FLAKE_DIR/hardware.nix, or drop the fileSystems block"
fi

# ── 5. Evaluate before touching anything ──────────────────────────────────
# This is the whole point of doing it in this order: a broken config fails
# here, as your user, with /etc/nixos still untouched and nothing installed.
say "Evaluating the flake"

# A flake in a git repo cannot see untracked files. Without this, a freshly
# generated hardware-configuration.nix is invisible and the eval fails with a
# confusing error about a missing file that is right there.
git -C "$REPO_DIR" add -A

nix "${nixflags[@]}" eval --raw \
  "$FLAKE_DIR#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath" >/dev/null \
  || die "the config does not evaluate — nothing has been changed"
ok "evaluates"

# ── 6. Point /etc/nixos at the repo ───────────────────────────────────────
say "Linking /etc/nixos"

if [ "$(readlink -f /etc/nixos)" = "$FLAKE_DIR" ]; then
  ok "already points at $FLAKE_DIR"
else
  if [ -e /etc/nixos ] && [ ! -L /etc/nixos ]; then
    backup="/etc/nixos.backup.$(date +%Y%m%d-%H%M%S)"
    sudo mv /etc/nixos "$backup"
    warn "moved the old /etc/nixos to $backup"
  fi
  sudo ln -sfn "$FLAKE_DIR" /etc/nixos
  ok "/etc/nixos -> $FLAKE_DIR"
fi

# ── 7. Switch ─────────────────────────────────────────────────────────────
say "Ready to switch"

confirm "Build and activate $HOST now?" || { echo "   stopped before the switch"; exit 0; }

# NIX_CONFIG rather than flags, because it reaches every nix call that
# nixos-rebuild makes internally, not just the outer one.
#
# The substituter is repeated here on purpose. It is configured in
# configuration.nix, but that config only exists AFTER this switch — so
# without it the very first build compiles noctalia from source, which takes
# the better part of an hour. Only root is a trusted user, which is why this
# goes on the sudo'd command and not on the eval above.
sudo env NIX_CONFIG="experimental-features = nix-command flakes
extra-substituters = https://noctalia.cachix.org
extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" \
  nixos-rebuild switch --flake "$FLAKE_DIR#$HOST"

say "Done"
echo "   Log out and back in — AMD_DEBUG and the session variables only apply to a fresh login."
echo "   From now on, rebuild with:  up"
