#!/usr/bin/env bash
# Shared orchestration; each distribution owns its package list and repositories.
set -euo pipefail

native_preflight() {
  if [[ "${1:-}" == --help && $# == 1 ]]; then
    printf '%s\n' 'Run this script as your normal user from its checkout.' \
      'Edit nixos/profile.nix for your username, home and checkout path first.' \
      'Installs native applications, applies Nix dotfiles, configures the desktop, and enables greetd for the next boot.'
    exit 0
  fi
  [[ $# == 0 ]] || { printf '%s\n' 'Only --help is supported.' >&2; exit 2; }
  [[ $(id -u) != 0 ]] || { printf '%s\n' 'Run as your normal user, not sudo.' >&2; exit 1; }
  [[ $(uname -s) == Linux && ! -e /etc/NIXOS ]] || { printf '%s\n' 'Use nixos-setup.sh on NixOS.' >&2; exit 1; }
  [[ $(uname -m) == x86_64 ]] || { printf '%s\n' 'The editor profile currently targets x86_64-linux.' >&2; exit 1; }
  [[ ! -e /run/ostree-booted ]] || { printf '%s\n' 'This DNF installer requires conventional Fedora, not an Atomic desktop.' >&2; exit 1; }
  command -v sudo >/dev/null
  sudo -v
  previous_display_manager=$(readlink -f /etc/systemd/system/display-manager.service || true)
  work=$(mktemp -d)
  trap 'rm -rf -- "$work"' EXIT
  # shellcheck disable=SC1091
  . /etc/os-release
}

native_apply() {
  for executable in nix start-umbriel noctalia noctalia-greeter-session noctalia-greeter-apply-appearance; do
    command -v "$executable" >/dev/null || { printf 'Missing installed command: %s\n' "$executable" >&2; exit 1; }
  done
  sudo systemctl enable --now nix-daemon.socket
  export NIX_REMOTE=daemon
  nixflags=(--extra-experimental-features 'nix-command flakes')
  nix "${nixflags[@]}" store ping --store daemon
  flake="path:$repo_dir/nixos"
  profile=$(nix "${nixflags[@]}" eval --no-write-lock-file --raw "$flake#lib.deployment.profileName")
  # Bootstrap checks the configured identity and architecture before building.
  bash "$repo_dir/nixos/bootstrap.sh" --repo-dir "$repo_dir" --profile "${profile}-desktop" \
    --activate --backup-extension "before-native-$(date +%Y%m%d-%H%M%S)"
  hash -r
  "$HOME/.local/bin/desktop-apply"

  # Use the packaged helper/account and PAM stack instead of replacing PAM.
  [[ -f /etc/pam.d/greetd ]] || { printf '%s\n' 'The greetd package did not install its PAM configuration.' >&2; exit 1; }
  [[ -f /usr/share/wayland-sessions/umbriel.desktop ]] || { printf '%s\n' 'Umbriel session desktop file is missing.' >&2; exit 1; }
  sudo noctalia-greeter-apply-appearance --setup-system
  greeter_user=$(sudo noctalia-greeter-apply-appearance --print-greeter-user)
  getent passwd "$greeter_user" >/dev/null
  sudo cat /etc/greetd/config.toml > "$work/greetd.toml"
  if sudo test -f /var/lib/noctalia-greeter/greeter.toml; then
    sudo cat /var/lib/noctalia-greeter/greeter.toml > "$work/greeter.toml"
  else
    : > "$work/greeter.toml"
  fi
  python3 "$repo_dir/nixos/native/configure.py" "$work" "$(id -un)" "$greeter_user"
  native_install_file "$work/greetd.toml" /etc/greetd/config.toml 644 root root
  greeter_group=$(id -gn "$greeter_user")
  native_install_file "$work/greeter.toml" /var/lib/noctalia-greeter/greeter.toml 640 "$greeter_user" "$greeter_group"
  native_install_file "$work/greeter.rules" /etc/polkit-1/rules.d/49-noctalia-greeter-config.rules 644 root root
  native_install_file "$work/desktop.service" /etc/systemd/user/config-desktop-apply.service 644 root root
  sudo systemctl daemon-reload
  systemctl --user daemon-reload
  systemctl --user enable config-desktop-apply.service
  sudo systemctl start accounts-daemon.service

  # Resolve the actual display-manager alias; do not stop the active session.
  previous=${previous_display_manager:-$(readlink -f /etc/systemd/system/display-manager.service || true)}
  if [[ -n "$previous" && "${previous##*/}" != greetd.service ]]; then
    sudo systemctl disable "${previous##*/}"
  fi
  if ! sudo systemctl enable greetd.service; then
    [[ -z "$previous" ]] || sudo systemctl enable "${previous##*/}"
    printf '%s\n' 'Could not enable greetd; restored the previous display-manager enablement.' >&2
    exit 1
  fi
  sudo systemctl set-default graphical.target
  printf '\n%s\n' 'Run editor-setup after login to install native editor plugins and notebook dependencies.'
  printf '\n%s\n' 'Setup complete. Reboot and select Umbriel in Noctalia Greeter.' \
    'The current graphical session was left running. Wallpaper/color auto-sync runs from Noctalia after login.' \
    'GPU drivers, firmware and existing network configuration remain distribution-managed.'
}

native_install_file() {
  local source=$1 target=$2 mode=$3 owner=$4 group=$5
  if sudo test -e "$target" && ! sudo cmp -s -- "$source" "$target"; then
    sudo cp -a --backup=numbered -- "$target" "$target.before-config"
  fi
  sudo install -D -m "$mode" -o "$owner" -g "$group" -- "$source" "$target"
}

# Debian stable's Neovim is older than LazyVim requires. Prefer a suitable
# distribution binary; otherwise install the verified official upstream release.
native_neovim() {
  if [[ -x /usr/bin/nvim ]] && /usr/bin/nvim --headless -u NONE \
    -c "if !has('nvim-0.11.2') | cquit 1 | endif" -c qa; then
    return
  fi
  version=v0.12.6
  destination="${XDG_DATA_HOME:-$HOME/.local/share}/native-apps/neovim-$version"
  if [[ ! -x "$destination/bin/nvim" ]]; then
    curl --fail --location --proto '=https' --tlsv1.2 \
      "https://github.com/neovim/neovim/releases/download/$version/nvim-linux-x86_64.tar.gz" -o "$work/neovim.tar.gz"
    printf '%s  %s\n' '474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87' "$work/neovim.tar.gz" | sha256sum --check
    staging=$(mktemp -d "$work/neovim.XXXXXXXX")
    tar --extract --gzip --file "$work/neovim.tar.gz" --strip-components=1 --directory "$staging"
    mkdir -p -- "${destination%/*}"
    if [[ -e "$destination" ]]; then mv --backup=numbered -- "$destination" "$destination.before-native-editor"; fi
    mv -- "$staging" "$destination"
  fi
  mkdir -p -- "$HOME/.local/bin"
  link="$HOME/.local/bin/nvim"
  if [[ "$(readlink -- "$link" || true)" != "$destination/bin/nvim" ]]; then
    if [[ -e "$link" || -L "$link" ]]; then mv --backup=numbered -- "$link" "$link.before-native-editor"; fi
    ln -s -- "$destination/bin/nvim" "$link"
  fi
}
