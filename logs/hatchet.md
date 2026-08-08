# hatchet

Changelog for chezmoi-managed Hatchet infrastructure.

## 2026-08-08 -- Daily Hatchet session-cleanup job (chezmoi-managed, cross-machine)

- **Context**: Hatchet-lite (the workflow engine behind Impulse, in `e8n-hatchet-hatchet-postgres-1`) ships **no garbage collection for its `UserSession` table**. It grew unbounded to ~2.3M rows / 923MB before being pruned by hand. This job IS the missing GC.
- **What it does**: once a day, deletes the expired rows:
  `DELETE FROM "UserSession" WHERE "expiresAt" < now();`
  Run verified live on nimbus (`DELETE 0` after the manual prune, so the table is already clean and stays that way).
- **Why OS-level, not an Impulse cron**: Rai's standing preference is recurring jobs = Impulse, but this one is the deliberate exception. The cleanup exists to keep Hatchet healthy, so it must not depend on Hatchet being healthy to run. A launchd/systemd job is independent of the thing it maintains.
- **Files (chezmoi source -> deploy target)**:
  - `bin/executable_hatchet-session-cleanup.sh` -> `~/bin/hatchet-session-cleanup.sh`. Deploys on **macOS AND Linux**. A deliberate **no-op** where Docker or the container is absent (logs "skipping", exit 0), so it is harmless on any machine that does not run Hatchet. `psql` runs *inside* the container using the container's own `POSTGRES_USER`/`POSTGRES_DB` env, so **no credential is ever read or printed** by the host script.
  - `Library/LaunchAgents/com.rai.hatchet-session-cleanup.plist` -> `~/Library/LaunchAgents/...` (**macOS only**). `StartCalendarInterval` daily at **04:37 local** (off-peak, non-round minute). Not a `.tmpl` and no `onepasswordRead`, so `chezmoi apply` on it needs **no 1Password session** (same rationale as the whetstone plists). `PATH` includes `/opt/homebrew/bin` because launchd's minimal env otherwise cannot find the `docker` CLI, which would make the script falsely conclude "docker not found". Logs to `~/.logs/hatchet-session-cleanup.launchd.log` -- an **internal** path (a launchd stdio path on `/Volumes/ExternalNVMe` dies EX_CONFIG(78) before exec).
  - `dot_config/systemd/user/hatchet-session-cleanup.service` + `.timer` -> `~/.config/systemd/user/...` (**Linux only**). `OnCalendar=*-*-* 04:37:00`, `Persistent=true` (catches up after downtime).
- **`.chezmoiignore`**: the plist is gated `{{ if ne .chezmoi.os "darwin" }}` and the systemd units `{{ if ne .chezmoi.os "linux" }}`, so each OS applies only its own scheduler. The script (under `bin/`) deploys everywhere. Verified on nimbus with `chezmoi managed | grep hatchet`: only the plist + script are managed here, the systemd units are correctly ignored.
- **Deploy status (nimbus, 2026-08-08)**: LIVE. Targeted `chezmoi apply` of the two files (no 1Password needed -- neither is templated), script deployed executable, `plutil -lint` OK, test run exits 0 and logged "deleted 0 expired session(s)". LaunchAgent bootstrapped into `gui/$(id -u)`; `launchctl print` confirms the `04:37` calendar interval is registered and watching.
- **Owed**: a **full** `chezmoi apply` is still owed on nimbus (needs Rai's 1Password session) to reconcile the *other*, unrelated pending templates -- it was intentionally NOT run, and the two new files were applied in a targeted way instead, so nothing here is blocked on it.
- **kinto (Linux)**: gets the script + systemd units on its next `chezmoi update`. systemd user timers are not auto-enabled (matches the repo's existing systemd-service convention), so activating it there is a one-time:
  `systemctl --user daemon-reload && systemctl --user enable --now hatchet-session-cleanup.timer`
  Until kinto actually runs Hatchet the script no-ops, so this is only needed if/when Hatchet lands there.
