#!/usr/bin/env python3
"""Run packaged launchers with fake external services; never touch power policy."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

fixture = json.loads(Path(sys.argv[1]).read_text())
with tempfile.TemporaryDirectory() as temporary:
    log = Path(temporary) / "events"
    def run(program, args=(), status=0, **extra):
        log.write_text("")
        env = {k: v for k, v in os.environ.items()
               if not k.startswith(("TEST_", "__NV_", "__GLX_", "__VK_"))}
        env.update(LAUNCH_LOG=str(log), **extra)
        result = subprocess.run([fixture[program], *args], env=env, capture_output=True)
        assert result.returncode == status, (result.returncode, result.stderr)
        return [json.loads(line) for line in log.read_text().splitlines()]

    for name in ("performance", "game", "portableGame"):
        assert run(name, status=2) == []
    assert run("game", ["--integrated"], status=2) == []
    args = [fixture["target"], "argument with spaces", "$(touch should-never-exist)", "literal'quote"]
    events = run("game", args)
    assert [e["name"] for e in events] == ["powerprofilesctl", "gamemoderun", "test-target", "release"]
    assert events[1]["held"] == "1" and events[1]["offload"] == "1"
    assert events[2]["args"] == args[1:] and events[2]["vulkan"] == "NVIDIA_only"
    events = run("game", ["--integrated", *args])
    assert events[1]["offload"] is None and events[1]["held"] == "1"
    events = run("performance", args, status=19, TEST_TARGET_STATUS="19")
    assert [e["name"] for e in events] == ["powerprofilesctl", "test-target", "release"]
    assert events[1]["offload"] is None
    events = run("game", args, status=73, TEST_PROFILE_FAIL="1")
    assert [e["name"] for e in events] == ["powerprofilesctl"]
    events = run("portableGame", args)
    assert [e["name"] for e in events] == ["gamemoderun", "test-target"]
    assert events[1]["offload"] is None and events[1]["held"] is None
    assert not Path("should-never-exist").exists()
print("PASS: launcher ordering, offload/integrated modes, quoted arguments, refusal, exit status, release and portability")
