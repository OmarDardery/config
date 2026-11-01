# Developing this configuration

This repository uses Nix and Home Manager, Bash installers, and Python desktop
helpers. The Python helpers require `tomlkit`; there is no application server,
notebook, Go, Rust, or JavaScript project here.

## Start

From the repository root, on Linux with Nix installed:

```sh
nix-shell
bash scripts/dev.sh setup
codium .
```

The existing flake also exposes the same shell:

```sh
nix develop ./nixos
```

`shell.nix` reads the **root nixpkgs input** from `nixos/flake.lock`. It fetches
only that source, so entering the shell does not fetch Noctalia, Umbriel, or
other desktop inputs. `nix develop ./nixos` may resolve those flake inputs.
Neither command activates or rebuilds the desktop. Updating the existing
lockfile updates the development tools too; there is no second Nix pin.

The shell supplies Python 3.12, uv, Ruff, Basedpyright, nixd, nixfmt,
ShellCheck, shfmt, and Bash Language Server. uv installs `tomlkit`, pytest,
and debugpy from `uv.lock` into `.venv`, using the Nix interpreter.
Python downloads and user site-packages are disabled. There are no scientific
libraries, Jupyter kernels, compiler bundles, or global pip installs.

## VSCodium

Open **the repository root**, not just `nixos/`. Install the workspace's
recommended extensions when VSCodium offers them. Each is available on
[Open VSX](https://open-vsx.org/): Nix IDE, EditorConfig, direnv, Bash IDE,
Python, Python Debugger, Basedpyright, and Ruff. Basedpyright supplies Python
completion and type checking; Pylance is not required.

For automatic environment loading, including opening from the desktop:

```sh
direnv allow
```

The system profile already supplies direnv and nix-direnv. The `mkhl.direnv`
extension loads `.envrc` into the extension host and terminals, then restarts
extensions automatically when the environment changes. Allow the workspace
and wait for direnv to finish before using language servers. This also handles
an existing VSCodium process that was started outside the shell.
Without direnv integration, close existing VSCodium processes and launch
`codium .` from the shell above.

The workspace selects `.venv/bin/python`, Ruff formatting, pytest discovery,
and nixd/nixfmt. Its default integrated terminal enters the Nix shell.
Every task explicitly enters the shell too, including tasks started from a
desktop-launched editor; task execution does not depend on direnv startup.

Use **Run Task → dev: setup** once before Python test discovery. F5 offers
the helper tests and the real `office-convert.py --help` entry point.
Both launch configurations prepare `.venv` first and use its interpreter.
Tests use disposable directories and do not touch desktop state.

## Commands

These commands work inside or outside the development shell:

| Command | Purpose |
| --- | --- |
| `bash scripts/dev.sh setup` | Sync `.venv` from the committed lockfile |
| `bash scripts/dev.sh doctor` | Check tool versions and native debugpy imports |
| `bash scripts/dev.sh check` | Run lint, type checks, and helper regression tests |
| `bash scripts/dev.sh test -k reconcile` | Run selected tests |
| `bash scripts/dev.sh format` | Format tracked Nix/Bash files and Python sources |
| `bash scripts/dev.sh evaluate` | Evaluate system/home profiles using temporary CI hardware |
| `bash scripts/dev.sh build` | Build the configured system using local hardware; no activation |
| `bash scripts/dev.sh clean` | Remove Ruff/pytest caches |
| `bash scripts/dev.sh exec python3 --version` | Run a command in the pinned shell |

`lint`, `typecheck`, and `test` are also separate tasks. `format` intentionally
formats the repository's sources; review the diff before committing.
For a real local system build, first run:

```sh
bash nixos/native/copy-hardware.sh . --if-missing
bash scripts/dev.sh build
```

Evaluation checks a temporary copy with CI hardware. It does not write the local
hardware file. It requires fetching the desktop flake inputs and is separate
from the faster `check` command. CI runs both helper checks and the existing
system/desktop evaluation job.

## Troubleshooting

- Missing tools after opening from the desktop: install the recommended direnv
  extension, allow `.envrc`, then run **direnv: Reset and reload environment**.
- Wrong Python interpreter selected earlier: use **Python: Select Interpreter**
  and select `.venv/bin/python`; the default setting does not override a cached
  manual selection. After moving a checkout, delete `.venv` and run `setup` again.
- Changed dependencies: run `nix-shell --run 'uv lock'`, commit `uv.lock`, then
  run `setup`. Normal tasks use `--locked` and refuse a stale lockfile.
- Native import failure: use `doctor` and inspect the failing shared object's
  dependencies before adding libraries. The current runtime dependency,
  `tomlkit`, is pure Python; debugpy's native modules are checked by `doctor`.
  Its process-attach helper links `libstdc++` and `libgcc_s`, so the shell scopes
  `LD_LIBRARY_PATH` to the compiler runtime libraries for that helper. It does
  not install a compiler or rely on host `nix-ld`.
- Office conversion, Steam setup, Flatpak font refresh, and native installers
  need their actual host applications. The development shell tests helper
  logic; run integration checks on the target machine before deployment.
