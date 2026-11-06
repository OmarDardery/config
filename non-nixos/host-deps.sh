#!/usr/bin/env bash
# Only the distro can provide Flatpak's host sandbox/desktop integration.
set -euo pipefail
if command -v flatpak >/dev/null; then exit 0; fi
if ! command -v sudo >/dev/null; then
  printf '%s\n' 'Install Flatpak and the desktop portal using your distro administrator, then retry.' >&2
  exit 1
fi
printf '%s\n' 'Installing native Flatpak and desktop portal support (sudo required).'
if command -v apt-get >/dev/null; then
  sudo apt-get update
  sudo apt-get install -y flatpak xdg-desktop-portal xdg-desktop-portal-gtk
elif command -v dnf >/dev/null; then
  sudo dnf install -y flatpak xdg-desktop-portal xdg-desktop-portal-gtk
elif command -v pacman >/dev/null; then
  # Do not refresh only the package database or upgrade the whole host here.
  sudo pacman -S --needed flatpak xdg-desktop-portal xdg-desktop-portal-gtk
elif command -v zypper >/dev/null; then
  sudo zypper --non-interactive install flatpak xdg-desktop-portal xdg-desktop-portal-gtk
else
  printf '%s\n' 'Unsupported host package manager. Install Flatpak and a desktop portal, then retry.' >&2
  exit 1
fi
command -v flatpak >/dev/null || { printf '%s\n' 'Native Flatpak is still unavailable.' >&2; exit 1; }
