#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
if [[ ${CONFIG_DEV_SHELL:-} != 1 ]]; then
  # Bash's %q preserves spaces and shell metacharacters in every argument.
  printf -v invocation '%q ' bash "$repo_dir/scripts/dev.sh" "$@"
  # The bootstrap shell must also work on Nix installations without channels.
  export NIX_BUILD_SHELL=${NIX_BUILD_SHELL:-$(command -v bash)}
  exec nix-shell "$repo_dir/shell.nix" --run "exec $invocation"
fi
cd -- "$repo_dir"
export UV_PROJECT_ENVIRONMENT="$repo_dir/.venv"

sync_python() {
  uv sync --locked --python "$UV_PYTHON"
}

shell_files() {
  git ls-files -z -- '*.sh' | xargs -0 -r "$@"
}

case ${1:-help} in
setup)
  sync_python
  ;;
exec)
  shift
  exec "$@"
  ;;
terminal)
  exec bash --noprofile --norc -i
  ;;
lint)
  ruff check .
  shell_files shellcheck --shell=bash --severity=warning
  ;;
format)
  git ls-files -z -- '*.nix' | xargs -0 -r nixfmt
  shell_files shfmt -w -ln bash -i 2
  ruff format .
  ;;
typecheck)
  sync_python
  basedpyright
  ;;
test)
  sync_python
  shift
  .venv/bin/python -m pytest "$@"
  ;;
doctor)
  sync_python
  nix --version
  nixd --version
  nixfmt --version
  shellcheck --version
  shfmt --version
  bash-language-server --version
  uv --version
  ruff --version
  basedpyright --version
  .venv/bin/python -Xfrozen_modules=off - <<'PY'
import ctypes
from pathlib import Path
import sys

import debugpy
import pytest
import tomlkit
from debugpy._vendored import force_pydevd

print(sys.version)
print("tomlkit, pytest and debugpy (including pydevd) imported")
for library in Path(debugpy.__file__).parent.rglob("attach_linux_amd64.so"):
    ctypes.CDLL(str(library))
    print(f"Loaded native debugger library: {library.name}")
PY
  ;;
evaluate)
  # Evaluate a copy: the laptop's hardware file is deliberately untracked.
  work=$(mktemp -d)
  trap 'rm -rf -- "$work"' EXIT
  cp -R nixos "$work/nixos"
  cp .github/ci-hardware.nix "$work/nixos/hardware-configuration.nix"
  flake="path:$work/nixos"
  nix flake check "$flake" --no-build --no-write-lock-file
  profile=$(nix eval --raw "$flake#lib.deployment.profileName" --no-write-lock-file)
  for name in "$profile" "$profile-desktop"; do
    nix eval --raw "$flake#homeConfigurations.$name.activationPackage.drvPath" --no-write-lock-file
  done
  ;;
build)
  [[ -f nixos/hardware-configuration.nix ]] || {
    printf '%s\n' 'Copy your hardware file first: bash nixos/native/copy-hardware.sh . --if-missing' >&2
    exit 1
  }
  host=$(nix eval --raw ./nixos#lib.deployment.hostName --no-write-lock-file)
  nix build "./nixos#nixosConfigurations.$host.config.system.build.toplevel" --no-write-lock-file
  ;;
check)
  bash "$repo_dir/scripts/dev.sh" lint
  bash "$repo_dir/scripts/dev.sh" typecheck
  bash "$repo_dir/scripts/dev.sh" test
  ;;
clean)
  # Remove only disposable tool caches, keeping .venv and application data.
  rm -rf -- .pytest_cache .ruff_cache
  ;;
*)
  printf '%s\n' 'Usage: bash scripts/dev.sh setup|doctor|lint|format|typecheck|test [pytest args]|evaluate|build|check|clean|terminal|exec COMMAND [ARGS...]'
  [[ ${1:-help} == help ]]
  ;;
esac
