"""Exercise state replacement against disposable files, never desktop state."""

import stat

import pytest

from state_file import replace, snapshot


def test_replace_backs_up_exact_bytes_and_preserves_mode(tmp_path):
    path = tmp_path / "settings.toml"
    path.write_bytes(b"# user's comment\nactive = true\n")
    path.chmod(0o640)
    original = snapshot(path)

    backup = replace(path, original, b"active = false\n", preserve_mode=True)

    assert backup is not None
    assert backup.read_bytes() == original[0]
    assert path.read_bytes() == b"active = false\n"
    assert stat.S_IMODE(path.stat().st_mode) == 0o640


def test_replace_rejects_intervening_write(tmp_path):
    path = tmp_path / "settings.toml"
    path.write_bytes(b"first")
    original = snapshot(path)
    path.write_bytes(b"another writer's data")

    with pytest.raises(ValueError, match="changed during migration"):
        replace(path, original, b"replacement")

    assert path.read_bytes() == b"another writer's data"
    assert not list(tmp_path.glob(".settings.toml.migration-*"))


def test_snapshot_rejects_symlink(tmp_path):
    target = tmp_path / "real"
    target.write_bytes(b"do not touch")
    link = tmp_path / "link"
    link.symlink_to(target)

    with pytest.raises(OSError):
        snapshot(link)

    assert target.read_bytes() == b"do not touch"


def test_replace_missing_file_then_no_op(tmp_path):
    path = tmp_path / "new" / "state"
    assert snapshot(path, missing_ok=True) is None
    assert replace(path, None, b"new") is None
    assert replace(path, snapshot(path), b"new") is None
    assert path.read_bytes() == b"new"
    assert not list(path.parent.glob("state.backup-*"))
