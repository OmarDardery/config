"""Register a project's .venv with Jupyter without installing project dependencies."""
import argparse
import hashlib
from pathlib import Path
import shlex
import subprocess
import sys


def project_root(start):
    start = Path(start).expanduser().resolve()
    for directory in (start, *start.parents):
        if (directory / '.venv').is_dir():
            return directory
        if (directory / 'pyproject.toml').exists() or (directory / '.git').exists():
            break
    raise RuntimeError(f'No project .venv found from {start}')


def register(start):
    root = project_root(start)
    # Resolving this symlink would lose the virtual environment's sys.prefix.
    python = root / '.venv/bin/python'
    if not python.is_file():
        raise RuntimeError(f'Missing interpreter: {python}; create the environment with uv sync or uv venv')
    try:
        check = subprocess.run([str(python), '-c', 'import ipykernel'], capture_output=True, text=True)
    except OSError as error:
        raise RuntimeError(f'Cannot run {python}: {error}') from error
    if check.returncode:
        raise RuntimeError(
            f'{python} cannot import ipykernel. In the project, run uv add --dev ipykernel, '
            f'or uv pip install --python {shlex.quote(str(python))} ipykernel.\n{check.stderr.strip()}'
        )
    name = 'project-' + hashlib.sha256(str(root).encode()).hexdigest()[:16]
    display = f'Python ({root.name} .venv)'
    result = subprocess.run(
        [str(python), '-m', 'ipykernel', 'install', '--user', '--name', name, '--display-name', display],
        capture_output=True, text=True,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    print(f'Registered {display}; select it in the notebook kernel picker.', file=sys.stderr)
    print(name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('project', nargs='?', default='.')
    args = parser.parse_args()
    try:
        register(args.project)
    except RuntimeError as error:
        parser.exit(1, f'{error}\n')
