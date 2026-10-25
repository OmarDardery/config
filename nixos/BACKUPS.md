# Home backups

`system/backups.nix` backs up the configured user's home to `/mnt/storage/backup`
with Restic encryption. A daily persistent timer catches up after the laptop has
been off, with up to an hour of scheduling jitter. The job retains 7 daily, 4 weekly
and 6 monthly snapshots, prunes older snapshots according to that policy, and
checks repository metadata after each run.

Caches, trash, downloaded Steam games/shader caches, `node_modules`, `.venv` and
`.direnv` are excluded. Documents, config files and game saves remain included.
Files elsewhere on `/mnt/storage`, such as `/mnt/storage/Coding`, are not included.
This is a live file backup; close applications whose databases must be consistent.

The job requires the `/mnt/storage` filesystem to mount successfully. It will not
write backups into an empty mount directory on the root disk. A dependent service
generates `/var/lib/restic/home.password` on first use,
with root-only access. Existing passwords are never overwritten. The repository
is initialized on the first successful run; an existing Restic repository must
use the same password.

## Verify the first backup

After rebuilding, start a run and inspect the result:

```sh
sudo systemctl start restic-backups-home.service
sudo journalctl -u restic-backups-home.service -n 50 --no-pager
systemctl list-timers restic-backups-home.timer
```

Keep a recovery copy of the password in a password manager or another safe
location. Losing the only password makes encrypted backups unusable. The password
is read at runtime and is never embedded in the Nix store or committed to Git.

A repository on the same physical drive as its source files cannot protect those
files from that drive failing. `/mnt/storage/backup` follows the requested path;
confirm the storage drive is separate from the source drive for disk-failure
protection, and keep another copy elsewhere for important files.

## Check and restore

Run these only after confirming `/mnt/storage` is mounted:

```sh
findmnt /mnt/storage
sudo restic-home snapshots
sudo restic-home check --read-data-subset=10%
sudo restic-home restore latest --target /tmp/restic-restore-test
```

Inspect restored files before relying on the job. The restore example writes to
a separate directory and does not replace your live home. The generated
`restic-home` wrapper uses the same locked Restic package and repository/password
settings as the scheduled service.
