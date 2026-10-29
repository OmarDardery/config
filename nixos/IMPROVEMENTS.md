# Configuration review

## Implemented

- Automated encrypted home backups to `/mnt/storage/backup`, with retention,
  metadata checks, low I/O priority and a mount dependency. Follow [BACKUPS.md](BACKUPS.md)
  to verify the first restore and preserve a recovery copy of the generated password.
- GitHub Actions evaluates the locked flake and builds focused portability,
  generated-config, script, migration and theme checks. Its hardware fixture lives
  only in a temporary checkout; the laptop's ignored hardware file is untouched.
  NVIDIA/kernel and full system builds remain explicit checks outside this workflow.
- Optional bundles keep gaming, engineering, containers and printing out of the
  default system. Direct module imports replace the flake-parts registration layer.
- With the containers bundle enabled, Docker starts through its socket when WinBoat or a development client needs it.
  Containers do not automatically start at boot until Docker is activated. Set
  `virtualisation.docker.enableOnBoot = true` if boot-time containers are needed.
- Fastfetch and Inkscape are removed, along with their managed palette templates
  and Fastfetch-specific packaging/tests. Personal application data is retained.
- Desktop initialization resets with the graphical session, and stale comments,
  historical audit prose and unused declarations have been cleaned up.

## Further changes that need evidence

The desktop already uses PRIME offload, zram, LAVD with power-profile integration,
bounded Nix builds, low-priority store maintenance and editor watcher/thread
limits. Additional schedulers or power managers need measurements to justify them.

| Change | Decision or evidence needed |
| --- | --- |
| Kernel/GPU comparison | Test NVIDIA and xpadneo builds, suspend, external displays and games before changing `linuxPackages_latest`, driver pins or `AMD_DEBUG=nodcc`. |
| sops-nix | Useful when encrypted credentials need to travel with Git. The local Restic password is already a runtime-only file; adding sops requires a chosen decryption key and recovery plan. |
| Tablet support | Tablet support remains enabled for the configured hardware. Check usage and idle power before disabling it. |
| Lower refresh rate or cheaper blur | The 165 Hz panel and live blur are deliberate visual choices. Compare battery use and responsiveness before sacrificing them. |

```sh
systemd-analyze
systemd-analyze critical-chain
systemd-cgtop
nix path-info -Sh /run/current-system
powerprofilesctl get
sudo systemctl stop scx.service
# Repeat the same workload and power profile using the normal kernel scheduler.
sudo systemctl start scx.service
```

Compare frame times, idle power, temperatures and build duration under the same
conditions. No measured FPS or battery-life gain is claimed from source cleanup.

## References

- [NixOS Restic module](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/backup/restic.nix)
- [NixOS Docker module](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/virtualisation/docker.nix)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Linux sched_ext](https://docs.kernel.org/scheduler/sched-ext.html)
