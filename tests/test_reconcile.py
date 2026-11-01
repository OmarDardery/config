"""Run the Noctalia reconciler in isolation using its actual CLI."""

import subprocess
import sys
import tomllib
from pathlib import Path


RECONCILER = Path(__file__).resolve().parents[1] / "nixos/pkgs/reconcile-noctalia.py"


def run_reconciler(state, desired, *args):
    return subprocess.run(
        [sys.executable, str(RECONCILER), str(state), str(desired), *args],
        check=True,
        capture_output=True,
        text=True,
    )


def test_dry_run_preserves_bytes_and_does_not_make_backup(tmp_path):
    state = tmp_path / "state.toml"
    desired = tmp_path / "desired.toml"
    state.write_text("# custom state\n[bar]\nheight = 32\nvisible = true\n")
    desired.write_text("[bar]\nheight = 32\n")
    original = state.read_bytes()

    result = run_reconciler(state, desired)

    assert "bar.height" in result.stdout
    assert state.read_bytes() == original
    assert not list(tmp_path.glob("*.backup-*"))


def test_apply_removes_redundant_keys_preserves_boolean_and_custom_value(tmp_path):
    state = tmp_path / "state.toml"
    desired = tmp_path / "desired.toml"
    state.write_text("config_version = 1\n[bar]\nheight = 32\nvisible = true\ncustom = 7\n")
    desired.write_text("[bar]\nheight = 32\nvisible = 1\n")
    original = state.read_bytes()

    run_reconciler(state, desired, "--apply")

    assert tomllib.loads(state.read_text()) == {
        "config_version": 1,
        "bar": {"visible": True, "custom": 7},
    }
    backups = list(tmp_path.glob("state.toml.backup-*"))
    assert len(backups) == 1
    assert backups[0].read_bytes() == original
    # Running twice must leave an already reconciled file alone.
    run_reconciler(state, desired, "--apply")
    assert list(tmp_path.glob("state.toml.backup-*")) == backups
