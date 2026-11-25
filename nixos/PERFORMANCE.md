# Performance policy

The host uses the native Linux scheduler, power-profiles-daemon and compressed
RAM swap. There is no sched-ext daemon.

## Battery (laptop)

The `power-policy` user service (`system/power.nix`, `scripts/power-policy.sh`)
switches automatically:

| State | Power profile | Panel refresh |
| --- | --- | --- |
| AC | balanced | 165 Hz |
| Battery | power-saver | 60 Hz |
| Game running under `gamemoderun` | performance | 165 Hz |

It reacts to plug/unplug events, and GameMode's start/end hooks switch the game
state, so add `gamemoderun %command%` to a game's Steam launch options. A
profile picked in Noctalia lasts until the next plug, unplug or game event. Run
`power-policy apply` to re-apply the automatic choice.

The NVIDIA dGPU uses fine-grained runtime power management: it powers off
(D3cold) whenever nothing uses it and wakes for `nvidia-offload`. `config-doctor`
shows battery draw, the dGPU runtime state, processes holding `/dev/nvidia*`
and the panel refresh rate. On battery, the dGPU should read `suspended`; an
app listed as holding it keeps it awake (several watts). Zed is wrapped to see only
the AMD Vulkan driver, so it never wakes the dGPU. The 80% charge cap in
`hardware.nix` is intentional and limits runtime by about a fifth.

The AMD iGPU drives the desktop. Use NixOS's `nvidia-offload COMMAND` for selected
games or GPU applications. Steam and GameMode are provided by their NixOS modules;
use `gamemoderun %command%` in a game's launch options when wanted. Steam's UI
scale is scoped to Steam and follows the configured laptop display scale.

Nix builds are limited to two parallel jobs and four cores, with lower scheduling
priority. Store cleanup uses NixOS's standard garbage-collection and optimisation
jobs. There is no second package updater or desktop activation daemon.

CachyOS latest from the release branch is selected via its pinned overlay in
`system/performance.nix`. Keep the CachyOS flake's nixpkgs input independent to
maximize cache hits. For kernel upgrades, use `config-apply --boot-only` instead
of switching the running system in the same session. Run `config-doctor` after
reboot and compare boot time, power state and driver availability.
The ASUS NVIDIA driver and suspend policy remain in `hardware.nix`.
Changes to drivers, display behavior and suspend/resume require physical testing.
