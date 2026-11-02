# python development

Run `nix develop`, or review `.envrc` and run `direnv allow`.
Commit the generated `flake.lock` to pin this project independently.
Close any running Codium instance, then launch `codium .` from the shell.

Create `.venv` here with `uv venv`, then `uv pip install -r requirements.txt`
or the project's `uv sync`. Activate with `source .venv/bin/activate`.
