# Performance policy

The host uses the native Linux scheduler, power-profiles-daemon and compressed
RAM swap. There is no sched-ext daemon or per-application power-profile wrapper.
Choose a profile through Noctalia or `powerprofilesctl`.

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
