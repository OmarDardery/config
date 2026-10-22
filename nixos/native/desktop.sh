#!/usr/bin/env bash
# Install native desktop packages after configuring the upstream-documented repository.
# No Nix installation or manual driver/service changes; normal package maintainer scripts still run.
set -euo pipefail
install=false
case "${1:---print}" in
  --print) ;;
  --install) install=true ;;
  *) printf '%s\n' 'Usage: desktop.sh [--print|--install]' >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { printf '%s\n' 'Too many arguments' >&2; exit 2; }
# shellcheck disable=SC1091
. /etc/os-release
case "$ID:${VERSION_CODENAME:-}:${VERSION_ID:-}" in
  debian:trixie:*) command=(apt-get install -t trixie-backports noctalia umbriel xdg-desktop-portal-umbriel noctalia-greeter) ;;
  debian:sid:*|ubuntu:resolute:*) command=(apt-get install noctalia umbriel xdg-desktop-portal-umbriel noctalia-greeter) ;;
  *)
    printf '%s\n' 'Use the installation method for your distribution in native/README.md.' >&2
    exit 1
    ;;
esac
printf '%s\n' 'Prerequisite: configure the matching Noctalia APT repository using the official installation guide.'
printf '%s\n' 'https://docs.noctalia.dev/noctalia/getting-started/installation/#debian'
printf 'sudo'; printf ' %q' "${command[@]}"; printf '\n'
if "$install"; then
  [[ $(id -u) != 0 ]] || { printf '%s\n' 'Run as your normal user.' >&2; exit 1; }
  sudo "${command[@]}"
fi
printf '%s\n' 'Then follow the official greeter guide to review greetd/PAM and switch login managers from a TTY.'
