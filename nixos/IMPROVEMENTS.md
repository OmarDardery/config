# Configuration review

The current desktop already has PRIME offload, zram, LAVD with power-profile
integration, bounded Nix builds, low-priority store maintenance, and editor
watcher/thread limits. Keep these as the baseline; additional scheduler or power
managers would need evidence from this laptop to justify their complexity.

## Prioritized follow-ups

| Priority | Change | Benefit and tradeoff | Required decision or evidence |
| --- | --- | --- | --- |
| 1 | Automated Restic backups | Protect home files, printer profiles and mutable desktop state, which Git and NixOS generations do not capture. Exclude caches, build output and reproducible dependencies. | Choose an external disk or remote destination, retention and a separate password; verify an actual restore. No backup destination is configured here. |
| 2 | CI for the existing flake checks | Catch config/schema regressions before merging. Start with evaluation, portability, script and theme checks; keep NVIDIA/system builds separate because they are expensive. | The host requires ignored `hardware-configuration.nix`. Use an explicit evaluation fixture in CI, never a made-up production disk layout. Add formatting/lint checks after normalizing the baseline. |
| 3 | Docker socket activation | `virtualisation.docker.enableOnBoot = false` can avoid starting Docker until a client needs it. WinBoat and development still need Docker. | Check WinBoat startup, container restart policies and any containers expected to run immediately after boot before changing it. |
| 4 | Compare GPU/kernel policies on hardware | `linuxPackages_latest` plus a manual NVIDIA pin gives newer support but requires checking module compatibility on updates. An ordinary channel kernel may reduce churn if its features suffice. | Build NVIDIA **and xpadneo**, then compare suspend, external displays and games with an older bootable generation available. Do not remove `AMD_DEBUG=nodcc` without testing stripe corruption. |
| 5 | sops-nix when adding managed credentials | Store encrypted backup/service secrets in Git and decrypt during activation rather than embedding plaintext in Nix expressions. | Choose an age key and recovery copy. Existing interactive logins alone do not justify adding another input. |
| 6 | Trim optional always-on services | Printing, USB printer discovery, Avahi, tablet support and Docker reflect real features, but unused ones may add background work. | Measure with `systemd-analyze blame`, `systemctl --type=service --state=running`, and `systemd-cgtop`; disable only features no longer used. |

## Applied cleanup

- Bind `desktop-config.service` to the graphical session so its oneshot state
  resets on logout and initialization can run at the next graphical login.
- Keep Flatpak enablement in its application/service module and KDE Connect
  daemon ownership in the existing native user unit.
- Remove unused module arguments, a redundant local alias, misleading comments
  and obsolete one-time migration instructions. Keep migration code that still
  protects existing user files.
- Extract Fastfetch colors in one `jq` process rather than seven after the
  upstream compatibility hook. Incomplete palettes fall back to native defaults;
  explicit CLI arguments remain last and retain precedence.

Duplicate references to the exact same Nix derivation do not create another
installed copy. These package-list changes simplify ownership; they do not
promise a smaller closure or faster desktop. No runtime performance gain is
claimed without measurements.

## Useful comparisons

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

Compare frame times, idle power, temperatures and build duration with the same
power profile, display refresh rate and workload. The existing 165 Hz display and
live blur are deliberate visual choices; reduce them only if battery measurements
show the tradeoff is worthwhile. Replacing Umbriel/Noctalia would be a workflow
change, with no demonstrated benefit from this source review.

## Upstream references

- [NixOS Restic module](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/backup/restic.nix)
- [NixOS Docker module](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/virtualisation/docker.nix)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Linux sched_ext](https://docs.kernel.org/scheduler/sched-ext.html)
