#!/usr/bin/env bash
# Use Home Manager's host integration rather than injecting driver libraries into apps.
set -euo pipefail
drivers=${1:?expected graphics library directory}
setup=${2:?expected Home Manager GPU setup executable}
if [[ $(readlink /run/opengl-driver || true) == "$drivers" &&
      $(readlink /etc/tmpfiles.d/non-nixos-gpu.conf || true) == "${setup%/bin/*}/lib/tmpfiles.d/non-nixos-gpu.conf" ]]; then
  exit 0
fi
command -v sudo >/dev/null || {
  printf 'Graphics integration needs an administrator: sudo %s\n' "$setup" >&2
  exit 1
}
printf '%s\n' 'Setting up Nix graphics libraries for desktop apps (sudo required).'
sudo -- "$setup"
[[ $(readlink /run/opengl-driver || true) == "$drivers" ]] || {
  printf '%s\n' 'Graphics setup did not create /run/opengl-driver; Home Manager was not activated.' >&2
  exit 1
}
