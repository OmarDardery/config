#!/usr/bin/env bash
# Debian applications, followed by the shared configuration-only profile.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=nixos/native/common.sh
source "$repo_dir/nixos/native/common.sh"
native_preflight "$@"
[[ "$ID" == debian ]] || { printf '%s\n' 'This installer requires Debian Trixie or Sid.' >&2; exit 1; }
case "${VERSION_CODENAME:-}" in
  trixie) repository=trixie; release=(-t trixie-backports) ;;
  sid|forky) # Sid commonly reports the current testing codename; verify the rolling release.
    [[ "${PRETTY_NAME:-}" == *sid* ]] || { printf '%s\n' 'Only Debian Trixie and Sid have a supported upstream desktop repository.' >&2; exit 1; }
    repository=unstable; release=() ;;
  *) printf '%s\n' 'Only Debian Trixie and Sid are supported.' >&2; exit 1 ;;
esac
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
curl --fail --location --proto '=https' --tlsv1.2 \
  https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb -o "$work/keyring.deb"
sudo dpkg -i "$work/keyring.deb"
curl --fail --location --proto '=https' --tlsv1.2 \
  "https://pkg.noctalia.dev/deb/noctalia-$repository.sources" -o "$work/noctalia.sources"
native_install_file "$work/noctalia.sources" "/etc/apt/sources.list.d/noctalia-$repository.sources" 644 root root
# VSCodium's documented signed package repository.
curl --fail --location --proto '=https' --tlsv1.2 \
  https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg -o "$work/vscodium.asc"
gpg --batch --dearmor --output "$work/vscodium.gpg" "$work/vscodium.asc"
native_install_file "$work/vscodium.gpg" /usr/share/keyrings/vscodium-archive-keyring.gpg 644 root root
cat > "$work/vscodium.sources" <<'SOURCES'
Types: deb
URIs: https://download.vscodium.com/debs
Suites: vscodium
Components: main
Architectures: amd64
Signed-by: /usr/share/keyrings/vscodium-archive-keyring.gpg
SOURCES
native_install_file "$work/vscodium.sources" /etc/apt/sources.list.d/vscodium.sources 644 root root
sudo apt-get update
sudo apt-get install -y \
  nix-bin nix-setup-systemd git git-lfs gh zsh zsh-autosuggestions zsh-syntax-highlighting kitty firefox-esr codium neovim \
  build-essential clangd clang-format cmake pkg-config nodejs npm golang-go rustc cargo imagemagick \
  thunar thunar-archive-plugin thunar-volman tumbler file-roller gvfs-backends gvfs-fuse \
  mpv imv papers libreoffice xournalpp flatpak \
  python3 python3-venv python3-tomlkit jq ripgrep fd-find bat btop fzf direnv zoxide \
  unzip zip 7zip xdg-user-dirs xdg-utils xdg-desktop-portal-gtk \
  pipewire-audio wireplumber pulseaudio-utils playerctl brightnessctl \
  wl-clipboard grim slurp swappy ffmpeg tesseract-ocr qrencode zbar-tools \
  accountsservice polkitd gnome-keyring libpam-gnome-keyring dbus-user-session \
  fonts-jetbrains-mono fonts-noto-color-emoji adwaita-icon-theme qt6-wayland qt6ct
sudo apt-get install -y "${release[@]}" noctalia umbriel xdg-desktop-portal-umbriel noctalia-greeter
# Debian names these binaries differently; expose portable names without replacing /usr/bin.
mkdir -p -- "$HOME/.local/bin"
for pair in bat:batcat fd:fdfind; do
  name=${pair%%:*}; executable=${pair#*:}
  if ! command -v "$name" >/dev/null; then
    [[ ! -e "$HOME/.local/bin/$name" && ! -L "$HOME/.local/bin/$name" ]] || continue
    ln -s "/usr/bin/$executable" "$HOME/.local/bin/$name"
  fi
done
export PATH="$HOME/.local/bin:$PATH"
native_neovim
native_apply
