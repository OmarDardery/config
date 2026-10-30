#!/usr/bin/env bash
# Fedora desktop packages; Terra is the community repository endorsed by upstream.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=nixos/native/common.sh
source "$repo_dir/nixos/native/common.sh"
native_preflight "$@"
[[ "$ID" == fedora && "${VERSION_ID:-}" =~ ^[0-9]+$ && "$VERSION_ID" -ge 44 ]] || {
  printf '%s\n' 'This installer requires conventional Fedora 44 or newer.' >&2; exit 1;
}
sudo dnf install -y ca-certificates curl
# Keep both package and metadata signature verification enabled.
curl --fail --location --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/terrapkg/subatomic-repos/main/terra.repo -o "$work/terra.repo"
native_install_file "$work/terra.repo" /etc/yum.repos.d/terra.repo 644 root root
sudo dnf install -y --refresh terra-release
cat > "$work/vscodium.repo" <<'REPO'
[vscodium]
name=VSCodium
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
REPO
native_install_file "$work/vscodium.repo" /etc/yum.repos.d/vscodium.repo 644 root root
sudo dnf install -y \
  nix nix-daemon git git-lfs gh zsh zsh-autosuggestions zsh-syntax-highlighting kitty firefox codium neovim \
  Thunar thunar-archive-plugin thunar-volman tumbler file-roller gvfs-smb gvfs-mtp \
  mpv imv papers libreoffice xournalpp flatpak \
  python3 python3-tomlkit jq ripgrep fd-find bat btop fzf direnv zoxide yazi starship \
  unzip zip 7zip xdg-user-dirs xdg-utils xdg-desktop-portal-gtk \
  pipewire pipewire-pulseaudio wireplumber pulseaudio-utils playerctl brightnessctl \
  wl-clipboard grim slurp swappy ffmpeg-free tesseract qrencode zbar \
  accountsservice polkit gnome-keyring gnome-keyring-pam \
  jetbrains-mono-fonts google-noto-color-emoji-fonts adwaita-icon-theme qt6-qtwayland qt6ct \
  noctalia umbriel-nightly xdg-desktop-portal-umbriel-nightly noctalia-greeter
native_neovim
native_apply
