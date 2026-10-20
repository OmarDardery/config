# Desktop performance policy

`system/performance.nix` owns the kernel, scheduler, power-profile service and
compressed swap. `system/nix.nix` owns build/maintenance priorities.
These are NixOS policies; portable Home Manager installs no kernel or scheduler.

## Current configuration

- Keep Nixpkgs' `linuxPackages_latest` kernel (Linux 7.3 on the current channel)
  with NVIDIA 615.78.08 open modules. The driver version and hashes match official
  Nixpkgs' new-feature package; no local kernel compatibility patch is used.
- Run upstream `scx_lavd` through NixOS's `services.scx`, using the smaller
  `pkgs.scx.rustscheds` package instead of the full Rust/C scheduler bundle.
- Use `--autopower`: LAVD reads power-profiles-daemon's active profile over D-Bus,
  falling back to CPU EPP/governor information. No patched PPD or scx_loader is
  required. Noctalia's power selector and `performance-run`/`game-run` share it.
- Keep upstream LAVD scheduling defaults. Do not combine multiple CPU schedulers,
  priority daemons or competing power managers.
- Nix daemon/build children inherit nice 5, batch CPU policy and best-effort I/O
  priority 6. Existing two-job/four-core build limits protect available memory.
  Nix GC/optimisation retain idle I/O and nice 19. Builds can take longer while
  interactive applications are busy; no hard CPU quota is imposed.
- Preserve NixOS's default zstd zram sizing and disk-swap fallback. Weekly SSD
  TRIM is already enabled by the upstream NixOS module; no extra timer is needed.

LAVD targets interactive and gaming workloads. This is a tunable policy, not a
measured FPS or battery-life improvement. Nice values are useful hints; resource
control semantics depend on the active scheduler. I/O priorities also depend on
the device's scheduler. Existing GPU workarounds, suspend policy, displays,
filesystem settings and the kernel/driver pair stay unchanged.

## NVIDIA and Linux 7.3 compatibility

The former NVIDIA 610.57.04 pin calls the older
`dmem_cgroup_register_region(size, name)` interface. Linux 7.3 changed its first
argument to a `dmem_cgroup_init` pointer, causing compilation to fail. NVIDIA
615.78.08 detects and handles that interface. Its version and all five hashes
come from [official Nixpkgs](https://github.com/NixOS/nixpkgs/blob/a73abadb83fd64aee8abce72cc56811a178c1905/pkgs/os-specific/linux/nvidia-x11/default.nix).
The [upstream driver code](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/615.78.08/kernel-open/nvidia/os-interface.c)
contains the conditional compatibility implementation.

Kernel selection, open modules, PRIME offload, suspend policy and flake inputs
are unchanged. A channel upgrade alone cannot fix an explicit old driver pin.

The `nvidia-open` flake check builds the actual kernel module: evaluation alone
cannot catch C compilation failures. Before activating, build it and the system:

```sh
cd ~/config/nixos
nix build '.#checks.x86_64-linux.nvidia-open' --no-link
nix build '.#nixosConfigurations.nixos.config.system.build.toplevel' --no-link
nh os switch
```

Reboot after activation to load matching kernel and driver modules, then check
`uname -r`, `nvidia-smi` and `systemctl status scx.service`. No lockfile update
is needed for this fix.

## Kernel/flake audit — 2026-10-18

| Source | Findings | Decision |
| --- | --- | --- |
| [CachyOS/linux-cachyos](https://github.com/CachyOS/linux-cachyos) | Official patches/configuration; links community Nix packaging. BMQ cannot use sched_ext. | Reference source; no local kernel recipe needed. |
| [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) | Dedicated Nix flake, release/pinned package sets and CPU variants. Maintainer reported compromised servers on October 15 and shut down Hydra/cache. | Do not add its cache or depend on unavailable builds. This is community packaging, not a CachyOS-maintained NixOS module. |
| [Chaotic Nyx](https://github.com/chaotic-cx/nyx/tree/nyxpkgs-unstable) | Community flake with cached CachyOS kernels and upstream configuration parity. Documents a restricted integration for stable NixOS; keep its own Nixpkgs pin for cache reuse. | Viable future CachyOS experiment, after matching NVIDIA/module builds and comparing on hardware. Avoid importing an entire overlay merely to enable LAVD. |
| [drakon64/nixos-cachyos-kernel](https://github.com/drakon64/nixos-cachyos-kernel) | Archived April 2025. | Do not adopt. |
| Locked Nixpkgs kernel + [sched-ext/scx](https://github.com/sched-ext/scx) | NixOS already packages the upstream scheduler and service; the configured kernel has sched_ext support. | Selected; no extra input, cache, overlay or custom derivation. |

The cache incident is confirmed by the [maintainer's own comment](https://github.com/xddxdd/nix-cachyos-kernel/issues/110#issuecomment-6189203183).
No claim is made that kernel artifacts were tampered with. A community flake's
source and its binary-cache trust are separate decisions. Recheck project status
before adopting it later.

For a future CachyOS comparison, choose a non-BMQ stable/LTS variant, pin its
flake, retain a bootable stock generation and build all external modules first
(NVIDIA open modules and xpadneo here). Do not globally enable CPU-specific
compiler flags: they invalidate ordinary package caches and expand rebuilds.
LTO/Zen4 kernels need an actual workload comparison to justify their build cost.

## Verify and compare

After rebuilding, check the service and active kernel scheduler:

```sh
systemctl status scx.service
cat /sys/kernel/sched_ext/state
cat /sys/kernel/sched_ext/root/ops
powerprofilesctl get
journalctl -b -u scx.service
```

Expect `enabled` and a LAVD name if the scheduler loaded. The NixOS service starts
only when `/sys/kernel/sched_ext` exists. Native CLI/config checks here do not
prove BPF attachment, suspend/resume behavior or performance on the laptop.

Compare the same game/build workload and power profile, first with LAVD, then
with the kernel's regular fair scheduler:

```sh
sudo systemctl stop scx.service
# Compare responsiveness, frame-time lows, build duration, power and temperatures.
sudo systemctl start scx.service
```

Stopping LAVD restores the normal fair scheduler without rebooting. For a
persistent rollback, set `services.scx.enable = false` in
`system/performance.nix` and rebuild. If startup itself misbehaves, choose an older
generation or append `systemd.mask=scx.service` to the boot entry temporarily.

Sources: [Linux sched_ext and fallback behavior](https://docs.kernel.org/scheduler/sched-ext.html),
[CachyOS scheduler guide](https://wiki.cachyos.org/configuration/sched-ext/),
[LAVD upstream](https://github.com/sched-ext/scx/tree/main/scheds/rust/scx_lavd),
[pinned autopower implementation](https://github.com/sched-ext/scx/blob/v1.1.2/rust/scx_utils/src/autopower.rs).
