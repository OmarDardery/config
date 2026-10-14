#!/usr/bin/env bash
# Debian 13 installer for the configured oad laptop. Run as oad.
set -euo pipefail

repo_url=https://codeberg.org/oadardery/configs.git
repo_dir="$HOME/configs"
session_file=/usr/share/wayland-sessions/umbriel-configs.desktop
session_launcher=/usr/local/bin/start-umbriel-configs

say() { printf '\n== %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
has_candidate() {
  local policy
  policy=$(apt-cache policy "$1") || return 1
  [[ "$policy" =~ Candidate:[[:space:]]+([^[:space:]]+) && "${BASH_REMATCH[1]}" != '(none)' ]]
}

[[ $# == 0 ]] || die 'Usage: bash debian-setup.sh'
[[ $(id -u) != 0 ]] || die 'run as your normal user, without sudo'
[[ $(id -un) == oad && "$HOME" == /home/oad ]] || die 'this deployment profile requires oad with HOME=/home/oad'
[[ $(uname -m) == x86_64 ]] || die 'this profile requires x86_64'
[[ -r /etc/os-release ]] || die 'cannot read /etc/os-release'
# os-release is system-owned, but parse only the two literal fields we need.
os_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"' | head -1)
os_version=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"' | head -1)
[[ "$os_id" == debian && "$os_version" == 13 ]] || die 'requires Debian 13 (trixie)'
[[ -d /run/systemd/system ]] || die 'a running systemd host is required'
for tool in sudo apt-get apt-cache curl; do command -v "$tool" >/dev/null || die "$tool is required"; done
[[ ! -e /etc/NIXOS ]] || die 'use nixos/bootstrap.sh on NixOS'

say 'Installing native Debian desktop and device services'
sudo -v
sudo apt-get update
packages=(
  ca-certificates curl git sudo xz-utils
  sddm gnome-session gnome-shell xwayland
  dbus-user-session libpam-systemd polkitd policykit-1-gnome
  gnome-keyring libpam-gnome-keyring libsecret-1-0
  xdg-desktop-portal udisks2 gvfs gvfs-backends bluez upower fwupd
  pipewire pipewire-audio pipewire-pulse wireplumber
  firmware-amd-graphics mesa-vulkan-drivers libgl1-mesa-dri
  fonts-dejavu-core fonts-noto-core fonts-noto-color-emoji
  flatpak docker.io docker-compose
  wireshark-common udev libmtp-common brightnessctl
  power-profiles-daemon gamemode locales
)
# NVIDIA is optional for login because this laptop renders the desktop on AMD.
# Install the Debian driver when the configured repositories offer it.
if has_candidate nvidia-driver; then
  packages+=(nvidia-driver nvidia-settings)
  nvidia_installed=true
else
  nvidia_installed=false
  printf '%s\n' 'NVIDIA driver unavailable in APT. Enable Debian contrib/non-free/non-free-firmware and rerun for GPU offload.' >&2
fi
# Debian's dumpcap permission prompt is answered explicitly for this account.
printf '%s\n' 'wireshark-common wireshark-common/install-setuid boolean true' | sudo debconf-set-selections
sudo env DEBIAN_FRONTEND=noninteractive apt-get --yes --no-remove install "${packages[@]}"
sudo usermod -aG docker,wireshark,dialout oad
if getent group kvm >/dev/null; then sudo usermod -aG kvm oad; fi

say 'Enabling native services'
sudo systemctl enable --force sddm.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now docker.service
# A current graphical login may be active. Let the next boot start SDDM.
if systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
fi
sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
sudo timedatectl set-timezone Africa/Cairo

say 'Installing Nix in multi-user mode when needed'
if ! command -v nix >/dev/null 2>&1 && [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  installer=$(mktemp)
  trap 'rm -f -- "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install -o "$installer"
  sh "$installer" --daemon --yes
  rm -f -- "$installer"
  trap - EXIT
fi
if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck disable=SC1091
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
command -v nix >/dev/null 2>&1 || die 'Nix installed but unavailable; open a new shell and rerun'
sudo systemctl enable --now nix-daemon.socket

say 'Configuring the Noctalia binary cache for this Nix daemon'
# Use extra-* settings so existing system cache settings are preserved.
cache_conf=/etc/nix/nix.conf
cache_line='extra-substituters = https://noctalia.cachix.org'
key_line='extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4='
for line in "$cache_line" "$key_line"; do
  if ! sudo grep -Fxq -- "$line" "$cache_conf"; then
    printf '%s\n' "$line" | sudo tee -a "$cache_conf" >/dev/null
  fi
done
sudo systemctl restart nix-daemon.service

say 'Getting the configuration checkout'
if [[ -e "$repo_dir" ]]; then
  [[ -f "$repo_dir/nixos/flake.nix" ]] || die "$repo_dir exists but is not the configs checkout"
  # A rerun may contain local changes. Leave them untouched.
  say "Using existing $repo_dir"
else
  git clone -- "$repo_url" "$repo_dir"
fi

say 'Building and activating the standalone Home Manager profile'
bash "$repo_dir/nixos/bootstrap.sh" --repo-dir "$repo_dir" --activate --backup-extension "debian-setup-$(date -u +%Y%m%dT%H%M%SZ)"

say 'Linking the Home Manager Mesa stack for Nix applications'
gpu_setup=$(nix --extra-experimental-features 'nix-command flakes' eval --no-write-lock-file --raw "path:$repo_dir/nixos#homeConfigurations.oad.config.targets.genericLinux.gpu.setupPackage.outPath")
[[ "$gpu_setup" == /nix/store/* && -x "$gpu_setup/bin/non-nixos-gpu-setup" ]] || die 'missing generic Linux GPU setup helper'
sudo "$gpu_setup/bin/non-nixos-gpu-setup"

say 'Installing tablet and embedded-device rules'
rules_output=$(nix --extra-experimental-features 'nix-command flakes' build --no-write-lock-file --no-link --print-out-paths "path:$repo_dir/nixos#deviceRules")
[[ "$rules_output" == /nix/store/* && "$rules_output" != *$'\n'* ]] || die 'device rules build returned an invalid path'
rules_found=false
while IFS= read -r -d '' rule; do
  rules_found=true
  sudo install -Dm644 "$rule" "/etc/udev/rules.d/$(basename -- "$rule")"
done < <(find -L "$rules_output" -type f -name '*.rules' -print0)
[[ "$rules_found" == true ]] || die 'device rules package had no udev rules'
printf 'uinput\n' | sudo tee /etc/modules-load.d/configs-uinput.conf >/dev/null
sudo modprobe uinput
sudo udevadm control --reload-rules

say 'Registering Umbriel with SDDM'
# The package's launcher enters the user's login shell before starting its
# systemd session. Resolve the active HM profile on every login, so updates work.
launcher_tmp=$(mktemp)
session_tmp=$(mktemp)
trap 'rm -f -- "$launcher_tmp" "$session_tmp"' EXIT
cat > "$launcher_tmp" <<'LAUNCHER'
#!/bin/sh
set -eu
user=$(id -un)
home=$(getent passwd "$user" | cut -d: -f6)
for profile in "$home/.nix-profile" "$home/.local/state/nix/profiles/home-manager/home-path"; do
  if [ -x "$profile/bin/start-umbriel" ]; then
    exec "$profile/bin/start-umbriel"
  fi
done
printf '%s\n' "Umbriel launcher missing from $home; rerun debian-setup.sh" >&2
exit 1
LAUNCHER
cat > "$session_tmp" <<'SESSION'
[Desktop Entry]
Name=Umbriel
Comment=Umbriel Wayland desktop
Exec=/usr/local/bin/start-umbriel-configs
TryExec=/usr/local/bin/start-umbriel-configs
Type=Application
DesktopNames=umbriel
SESSION
sudo install -Dm755 "$launcher_tmp" "$session_launcher"
sudo install -Dm644 "$session_tmp" "$session_file"

say 'Finished'
printf '%s\n' \
  'Reboot, choose Umbriel in SDDM, and sign in as oad.' \
  'GNOME is available as a fallback session.'
if [[ "$nvidia_installed" == false ]]; then
  printf '%s\n' 'NVIDIA offload needs the Debian driver; see the README.'
fi
