# Desktop performance policy

`system/performance.nix` owns the kernel, scheduler, power-profile service and
compressed swap. `system/nix.nix` owns build/maintenance priorities.
These are NixOS policies; portable Home Manager installs no kernel or scheduler.

## Current configuration

- Use Nixpkgs' `linuxPackages_latest` kernel with the explicitly pinned NVIDIA
  open driver in `hardware.nix`; no local kernel compatibility patch is used.
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

## Kernel and external modules

The NVIDIA version/hashes in `hardware.nix` come from
[official Nixpkgs](https://github.com/NixOS/nixpkgs/blob/a73abadb83fd64aee8abce72cc56811a178c1905/pkgs/os-specific/linux/nvidia-x11/default.nix).
Keep the explicit driver pin compatible with the selected kernel. Flake input
updates do not automatically update that pin. Evaluation cannot detect C API
incompatibilities: build the NVIDIA check and full system before activation.
The full system build also covers xpadneo.

```sh
cd ~/config/nixos
sudo nixos-rebuild build --flake path:.#nixos
nix build 'path:.#nixosConfigurations.nixos.config.system.build.toplevel' --no-link
nh os switch
```

Reboot after a kernel/driver change to load matching modules, then check
`uname -r`, `nvidia-smi` and `systemctl status scx.service`.

A custom kernel/cache is an optional experiment. Pin the source, verify the
cache's current provenance, retain a bootable stock generation, and build all
external modules before trying it. Avoid global CPU-specific compiler flags,
which expand rebuilds and prevent ordinary binary-cache reuse. See
[README.md](README.md) for deployment notes.

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
