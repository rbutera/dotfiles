# launchagents

Changelog for chezmoi-managed macOS LaunchAgents.

## 2026-06-03 -- nightly-health launchagent is kinto-only

- Added `io.focused.nightly-health.plist` (the Mon-Fri 07:00 system-health + docker-reclaim job; built in ~/focused, OpenSpec change `nightly-system-health`).
- It must deploy ONLY on kinto (the 24/7 Mac Mini with colima + the worktree docker stacks); latios has none of that.
- Mechanism: added host group `always_on = ["kinto"]` to `.chezmoidata.toml`, and guarded the plist in `.chezmoiignore` with `{{ if not (has .chezmoi.hostname .host_groups.always_on) }}` so it is ignored on every host except kinto.
- Reuse `always_on` for future kinto-only launchagents (worktree-janitor, cockpit, discord daemons) when they get chezmoi-ified.
- The plist stays INERT until armed: `chezmoi apply ~/Library/LaunchAgents/io.focused.nightly-health.plist && launchctl load <same>`.
