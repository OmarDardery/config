#!/usr/bin/env python3
"""Copy four native applications' dotfiles; never install or activate applications."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time


def github(value):
    for prefix in ("github:", "https://github.com/", "git@github.com:"):
        value = value.removeprefix(prefix)
    value = value.rstrip("/").removesuffix(".git")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", value):
        raise ValueError("expected a GitHub OWNER/REPO; use --ref for a revision")
    return value


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def atomic_write(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(data)
            stream.flush()
            os.chmod(temporary, 0o644)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def install(source, config, state):
    allowed = {"nvim", "VSCodium", "umbriel", "noctalia"}
    files = sorted(p for p in source.rglob("*") if p.is_file())
    if not files or any(p.is_symlink() for p in source.rglob("*")):
        raise ValueError("dotfiles must be regular files, without source symlinks")
    if any(p.relative_to(source).parts[0] not in allowed for p in files):
        raise ValueError("dotfiles must belong to nvim, VSCodium, umbriel or noctalia")
    manifest = state / "files.json"
    previous = json.loads(manifest.read_text()) if manifest.exists() else {}
    current = dict(previous)
    backup_root = state / "backups" / f"{time.time_ns()}-{os.getpid()}"

    def backup(path):
        target = backup_root / path.relative_to(config)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(path), target)
        print(f"Backup: {target}")

    def directory(path):
        if path == config:
            return
        directory(path.parent)
        if path.is_symlink():
            # Materialize an old Home Manager directory without writing to its store target.
            original = path.resolve()
            backup(path)
            if original.is_dir():
                shutil.copytree(original, path, symlinks=False)
        if path.exists() and not path.is_dir():
            backup(path)
        path.mkdir(exist_ok=True)

    config.mkdir(parents=True, exist_ok=True)
    for file in files:
        relative = file.relative_to(source)
        destination = config / relative
        key = str(destination)
        directory(destination.parent)
        wanted = digest(file)
        actual = digest(destination)
        if key in previous:
            if not destination.exists() and not destination.is_symlink():
                print(f"Keep local deletion: {destination}")
                continue
            if actual != previous[key] and actual != wanted:
                print(f"Keep local edit: {destination}")
                continue
        if actual != wanted or destination.is_symlink():
            if destination.exists() or destination.is_symlink():
                backup(destination)
            atomic_write(destination, file.read_bytes())
            print(f"Apply: {destination}")
        current[key] = wanted
    atomic_write(manifest, (json.dumps(current, indent=2) + "\n").encode())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", nargs="?", type=github, help="GitHub OWNER/REPO (default: OmarDardery/config)")
    parser.add_argument("--repo-dir", type=Path, default=Path.home() / "config")
    parser.add_argument("--ref", help="branch, tag or commit for a new checkout")
    parser.add_argument("--update", action="store_true", help="git pull --ff-only before applying; refuses tracked source edits")
    args = parser.parse_args()
    if sys.platform != "linux" or os.getuid() == 0:
        parser.error("run as your normal Linux user, without sudo")
    if Path("/etc/NIXOS").exists():
        parser.error("use the main NixOS flake to avoid conflicting with Home Manager")
    repo = args.repo_dir.expanduser().absolute()
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    state_home = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    if not config.is_absolute() or not state_home.is_absolute():
        parser.error("XDG_CONFIG_HOME and XDG_STATE_HOME must be absolute paths")
    config = config.resolve()
    state = state_home / "non-nixos-config"
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / "apply.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("another dotfiles apply is running")
        if repo.exists():
            origin = github(git(repo, "remote", "get-url", "origin"))
            if args.repository and args.repository != origin:
                parser.error("checkout origin differs; select another --repo-dir")
            if args.ref:
                parser.error("--ref only applies to a new checkout; switch existing branches with Git")
        else:
            repo.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(["git", "clone", "--", f"https://github.com/{args.repository or 'OmarDardery/config'}.git", str(repo)], check=True)
            if args.ref:
                git(repo, "checkout", args.ref)
        if args.update:
            if git(repo, "status", "--porcelain", "--untracked-files=no"):
                parser.error("checkout has tracked edits; commit them before #update, or apply without --update")
            git(repo, "pull", "--ff-only")
        install(repo / "non-nixos/dotfiles", config, state)
    print(f"Dotfiles applied from {repo / 'non-nixos'}. Restart the apps to reload.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
