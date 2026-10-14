"""Substitutes only the external power-profile and GameMode APIs in tests."""
import json
import os
from pathlib import Path
import subprocess
import sys

name = Path(sys.argv[0]).name
log = Path(os.environ["LAUNCH_LOG"])
def record(event):
    with log.open("a") as stream:
        stream.write(json.dumps(event) + "\n")

args = sys.argv[1:]
record({"name": name, "args": args, "held": os.environ.get("TEST_PROFILE_HELD"),
        "offload": os.environ.get("__NV_PRIME_RENDER_OFFLOAD"),
        "vulkan": os.environ.get("__VK_LAYER_NV_optimus")})
if name == "powerprofilesctl":
    assert args[:4] == ["launch", "--profile", "performance", "--"]
    if os.environ.get("TEST_PROFILE_FAIL"):
        sys.exit(73)
    env = dict(os.environ, TEST_PROFILE_HELD="1")
    try:
        status = subprocess.call(args[4:], env=env)
    finally:
        record({"name": "release"})
    sys.exit(status)
if name == "gamemoderun":
    os.execv(args[0], args)
# Mock target represents the game/build process; it doesn't launch real games.
assert name == "test-target"
sys.exit(int(os.environ.get("TEST_TARGET_STATUS", "0")))
