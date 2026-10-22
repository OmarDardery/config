#!/usr/bin/env python3
"""Prepare native service files without requiring privileges or replacing PAM."""
import json
import re
import sys
from pathlib import Path

import tomlkit


def configure(directory: Path, username: str, greeter_user: str) -> None:
    for name in (username, greeter_user):
        if not re.fullmatch(r"[a-z_][a-z0-9_-]*\$?", name):
            raise ValueError("Invalid account name")
    path = directory / "greetd.toml"
    document = tomlkit.parse(path.read_text())
    # An old autologin initial_session would bypass the requested greeter.
    document.pop("initial_session", None)
    session = document.setdefault("default_session", tomlkit.table())
    session["command"] = "/usr/bin/noctalia-greeter-session"
    session["user"] = greeter_user
    path.write_text(tomlkit.dumps(document))
    path = directory / "greeter.toml"
    document = tomlkit.parse(path.read_text())
    for section, settings in {
        "session": {"default": "umbriel"},
        "user": {"default": username},
        "keyboard": {"layout": "us,ara", "options": "grp:alt_shift_toggle"},
    }.items():
        document.setdefault(section, tomlkit.table()).update(settings)
    path.write_text(tomlkit.dumps(document))
    # Match the upstream action; only this active local account gets automatic sync.
    (directory / "greeter.rules").write_text(
        'polkit.addRule(function(action, subject) {\n'
        '  if (action.id === "org.noctalia.greeter.sync-appearance" &&\n'
        f'      subject.user === {json.dumps(username)} && subject.local && subject.active) {{\n'
        '    return polkit.Result.YES;\n'
        '  }\n'
        '});\n'
    )
    (directory / "desktop.service").write_text(
        "[Unit]\nDescription=Apply shared desktop preferences\n"
        "ConditionPathExists=%h/.local/bin/desktop-apply\nAfter=graphical-session-pre.target\n"
        "PartOf=graphical-session.target\n\n[Service]\nType=oneshot\n"
        "ExecStart=/bin/bash %h/.local/bin/desktop-apply\n\n"
        "[Install]\nWantedBy=graphical-session.target\n"
    )


if __name__ == "__main__":
    configure(Path(sys.argv[1]), sys.argv[2], sys.argv[3])
