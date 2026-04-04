# sshfs changelog

## 2026-03-29 — Fix nimbus automount failing with "Connection reset by peer"

**Problem:** The fstab sshfs entry for `nimbus` (Mac server) was failing via systemd automount. `mnt-nimbus.mount` showed `read: Connection reset by peer` and hit the systemd start rate limit. Manual `sshfs` from the user shell worked fine.

**Root causes:**

1. `/mnt/nimbus` was owned by `root:root` with `755` — sshfs needs the mounting user to have write access to the mount point.
2. More critically: systemd runs fstab mounts as root, and `/root/.ssh/known_hosts` had no entry for `nimbus`. SSH host key verification failed silently, surfacing only as `Connection reset by peer`.

**Fixes applied:**

- `sudo chown rai:rai /mnt/nimbus` — fixed mount point ownership.
- `ssh-keyscan nimbus | sudo tee /root/.ssh/known_hosts` — added nimbus host keys for root's SSH.
- `sudo systemctl reset-failed mnt-nimbus.automount mnt-nimbus.mount && sudo systemctl restart mnt-nimbus.automount` — cleared rate limit and restarted.

**Note:** If nimbus's SSH host key ever changes (e.g. macOS reinstall), root's known_hosts will need updating again.
