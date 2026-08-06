# tokenmaxx

## 2026-08-06

**Problem/motivation:** tokenmaxx's proxy daemon reads account credentials out of
the macOS login Keychain (service `com.rubriclabs.tokmax`). On nimbus (a Mac mini
driven headless over SSH + Parsec) the daemon kept failing every read with
`Keychain read failed`, so the proxy returned `503 ... needs re-login` and any
Claude Code routed through it (navi) broke.

Root cause: Keychain access on macOS is tied to the process's security/audit
session, not just the UID. The daemon had first come up over **SSH**, which is a
non-GUI session with no access to the login Keychain even when it is unlocked in
the GUI session. The daemon is a singleton, so later `tokenmaxx` runs from the
Aqua GUI terminal (Ghostty) just RPC'd to the SSH-born daemon instead of
replacing it. Bouncing the daemon from Ghostty (`tokenmaxx daemon stop && start`)
fixed it because the new daemon inherited the Aqua session.

To make that survive reboots without a manual "start it from Ghostty" step, added
a **LaunchAgent** (not a LaunchDaemon: a LaunchDaemon runs in the system session
and would reproduce the exact bug). Auto-login brings up the Aqua session on
boot, the agent loads into it, and the daemon gets Keychain access.

**Changes:**
- Added `host_groups.tokenmaxx = ["nimbus"]` in `.chezmoidata.toml`.
- Added `Library/LaunchAgents/sh.tokenmaxx.daemon.plist` (RunAtLoad + KeepAlive,
  runs the exact `bun .../dist/index.js daemon run` that works today).
- Gated it in `.chezmoiignore` so it only deploys on `host_groups.tokenmaxx`
  machines (nimbus for now).

**Load it (must be from the GUI/Aqua session, e.g. Ghostty on Parsec, not SSH):**
```
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/sh.tokenmaxx.daemon.plist
```
Then `tokenmaxx list` should read the Keychain. Also disable login-keychain
auto-lock once so sleep doesn't re-lock it: `security set-keychain-settings`.

**Gotchas / follow-ups:**
- The bun path in the plist is pinned to `.asdf/installs/bun/1.3.14`. If bun is
  upgraded via asdf, update the plist path (or repoint at a stable shim).
- Only ever start/bounce the daemon from the GUI session. Starting it over SSH
  re-anchors it to a non-GUI session and Keychain reads fail again.
- Full runbook lives at `~/notes/2026-08-06 tokenmaxx daemon keychain + LaunchAgent.md`.
