import tomllib

import pytest

from configure import configure


def test_native_configure_removes_autologin_and_preserves_unrelated_options(tmp_path):
    (tmp_path / "greetd.toml").write_text(
        '[terminal]\nvt = 2\n[initial_session]\ncommand = "old-autologin"\n'
    )
    (tmp_path / "greeter.toml").write_text('[appearance]\ntheme = "custom"\n')

    configure(tmp_path, "oad", "greeter")

    greetd = tomllib.loads((tmp_path / "greetd.toml").read_text())
    assert "initial_session" not in greetd
    assert greetd["terminal"]["vt"] == 2
    assert greetd["default_session"]["user"] == "greeter"
    greeter = tomllib.loads((tmp_path / "greeter.toml").read_text())
    assert greeter["appearance"]["theme"] == "custom"
    assert greeter["user"]["default"] == "oad"
    assert 'subject.user === "oad"' in (tmp_path / "greeter.rules").read_text()


def test_native_configure_rejects_invalid_account_before_writing(tmp_path):
    with pytest.raises(ValueError, match="Invalid account name"):
        configure(tmp_path, "invalid;account", "greeter")
    assert not list(tmp_path.iterdir())
