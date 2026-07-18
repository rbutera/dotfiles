# standup-brief launchagent

Changelog for `Library/LaunchAgents/io.focused.standup-brief.plist` and its
kinto-only gating.

## 2026-06-03 - add the standup-brief launchagent

Problem / motivation: Rai needs a team-facing Fusion/easyJet standup prep brief
DM'd to Discord before the 09:45 daily stand, every weekday, so he is not
reconstructing yesterday's work under time pressure at 09:44 (ADHD architecture,
Brita Filter Rule). Bead focused-3fox.

What changed:
- Added `Library/LaunchAgents/io.focused.standup-brief.plist`. Fires Mon-Fri
  09:25 local time via StartCalendarInterval. RunAtLoad false. PATH includes
  `/Users/rai/Library/pnpm` so the `ark` binary resolves under launchd's minimal
  environment, plus the asdf node shim dir (ark is a node CLI).
- The plist runs the thin wrapper
  `~/focused/scripts/standup-brief/standup-brief.sh`, which loads
  ARK_WHISPER_TOKEN from `~/focused/state/whisper-token`, confirms the Ark
  lifecycle server is ready, then runs `ark whisper command /standup-brief`
  to inject the skill into Florence's running MAIN session (not a headless run).
- Gated kinto-only in `.chezmoiignore` via the `always_on` host group, mirroring
  `io.focused.nightly-health.plist`.

Armed: deployed via `chezmoi apply` then `launchctl load`. Verified loaded with
`launchctl list | grep standup-brief`. Dry-run of the wrapper
(`STANDUP_DRY_RUN=1`) confirmed token + port + readyz path. Whisper endpoint auth
probed (bad token 401, real token 400-on-empty) to confirm the token is correct
without injecting a real command.

Disarm: `launchctl unload ~/Library/LaunchAgents/io.focused.standup-brief.plist`.
