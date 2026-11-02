#!/usr/bin/env python3
"""Initialize each template and evaluate its independent project lockfile."""
import json
from pathlib import Path
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parents[1]
def nix(*args,directory):
    subprocess.run(['nix','--extra-experimental-features','nix-command flakes',*args],cwd=directory,check=True,stdout=subprocess.DEVNULL)
with tempfile.TemporaryDirectory(prefix='config-project-templates-') as temporary:
    for name in ['nix','python','go','node','rust','cpp']:
        project=Path(temporary)/name;project.mkdir()
        nix('flake','init','-t',f'path:{ROOT}#{name}',directory=project)
        nix('flake','lock',directory=project)
        nix('eval','--raw',f'path:{project}#devShells.x86_64-linux.default.drvPath','--no-write-lock-file',directory=project)
        assert 'nixpkgs' in json.loads((project/'flake.lock').read_text())['nodes']
        assert str(ROOT) not in (project/'flake.nix').read_text()
        assert str(ROOT) not in (project/'shell.nix').read_text()
        print(f'{name}: initialized and evaluated with its own project lockfile',flush=True)
