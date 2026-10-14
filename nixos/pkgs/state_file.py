"""Best-effort, non-symlink state snapshots and durable backed-up replacement.

The final identity check detects intervening writes; uncooperative writers can
still race the subsequent rename. Callers do not stop GUI applications.
"""
import os
from pathlib import Path
import stat
import tempfile


def identity(info):
    return (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns,
            info.st_ctime_ns, info.st_mode)


def snapshot(path, *, missing_ok=False):
    path = Path(path)
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except FileNotFoundError:
        if missing_ok and not os.path.lexists(path):
            return None
        raise
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode):
            raise ValueError(f"{path} must be a regular, non-symlink file")
    except BaseException:
        os.close(fd)
        raise
    with os.fdopen(fd, "rb") as source:
        data = source.read()
        if identity(os.fstat(source.fileno())) != identity(before):
            raise ValueError(f"{path} changed while being read; retry")
    return data, identity(before)


def sync_directory(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def write_bytes(fd, data):
    with os.fdopen(fd, "wb") as output:
        output.write(data)
        output.flush()
        os.fsync(output.fileno())


def replace(path, original, updated, *, preserve_mode=False):
    """Back up exact bytes, then verify contents AND identity immediately before commit."""
    path = Path(path)
    if original is not None and original[0] == updated:
        if snapshot(path, missing_ok=True) != original:
            raise ValueError(f"{path} changed during migration; retry")
        return None
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    backup = None
    try:
        fd, name = tempfile.mkstemp(prefix=f".{path.name}.migration-", dir=path.parent)
        temporary = Path(name)
        write_bytes(fd, updated)
        if preserve_mode and original is not None:
            os.chmod(temporary, stat.S_IMODE(original[1][-1]))
        if original is not None:
            fd, name = tempfile.mkstemp(prefix=f"{path.name}.backup-", dir=path.parent)
            backup = Path(name)
            write_bytes(fd, original[0])
            sync_directory(path.parent)
        if snapshot(path, missing_ok=True) != original:
            raise ValueError(f"{path} changed during migration; backup retained; retry")
        os.replace(temporary, path)
        temporary = None
        sync_directory(path.parent)
        return backup
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
