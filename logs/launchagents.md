# launchagents

Changelog for chezmoi-managed macOS LaunchAgents.

## 2026-07-21 -- Re-added dev.onorca.serve, NIMBUS ONLY (headless); kinto is headed

- Plan (Rai): **headless Orca serve on nimbus, headed desktop Orca on kinto.** So `dev.onorca.serve.plist` is back, gated in `.chezmoiignore` on `hostname == nimbus` only (kinto uses the desktop app, no launchd).
- The two blockers that sank it on kinto are now understood + preconditioned in the plist header: (1) single-instance lock (serve needs NO desktop Orca running), (2) macOS quarantine (`xattr -dr com.apple.quarantine /Applications/Orca.app`, else the first-launch GUI prompt silently blocks the headless spawn). Plus load in the Aqua domain (`launchctl bootstrap gui/$(id -u)`).
- Direct-exec + explicit PATH (no login zsh -> avoids the p10k instant-prompt mangling). Arch-aware brew path.

## 2026-07-20 (later) -- REMOVED dev.onorca.serve (launchd headless serve is a dead end)

- Killed + removed the `dev.onorca.serve.plist` LaunchAgent (booted out, deleted deployed copy, `git rm`'d the template, removed the `.chezmoiignore` gate). Per Rai: he'll start the Orca remote session from the **desktop app** instead.
- Why it never worked (asar-extracted from `out/main/index.js`): (1) `orca serve` is subject to the Electron **single-instance lock** and is NOT exempt (`ORCA_BYPASS_SINGLE_INSTANCE_LOCK` requires `!isServeMode`), so it silently exits whenever the desktop Orca app holds the lock; (2) even solo, a LaunchAgent's session isn't a rich enough "persistent terminal provider" for `createServeDesktopActivationGate`, so it stays stuck `initializing` and never binds. Headless serve wants a real logged-in terminal, not a plain LaunchAgent.
- The **`agentic = ["kinto","nimbus"]` host group** in `.chezmoidata.toml` was LEFT in place (harmless, reusable for future agent-runtime services). Remove it if it stays unused.

## 2026-07-20 -- Added dev.onorca.serve (Orca Remote Server, agentic hosts) [SUPERSEDED same day, see above]

- New LaunchAgent `dev.onorca.serve.plist` runs `orca serve` (headless Remote Orca Server) at login + KeepAlive, so kinto/nimbus are always reachable as Orca execution targets from latios/lancelot/phone.
- Runs under `zsh -l -i -c "exec orca serve ..."` so it inherits Rai's FULL login+interactive shell env (PATH incl. `~/.local/bin` for the orca CLI symlink, asdf/mise shims, brew shellenv). If `-i` ever misbehaves in the launchd (no-tty) context, drop it to `-l -c` and source the needed bits explicitly.
- Pairing address = `{{"{{ .chezmoi.hostname | trimSuffix \".local\" }}"}}.piranha-wyvern.ts.net` (Tailscale MagicDNS). `.local` is trimmed defensively because nimbus sometimes reports `nimbus.local`. Fixed port 6768.
- New host group `agentic = ["kinto", "nimbus"]` in `.chezmoidata.toml`; gated in `.chezmoiignore` so the plist deploys only on agentic darwin hosts (same pattern as the chaching/always_on agents).
- Orca itself is now installed/updated via the auto-bumping cask `brew install --cask stablyai/orca/orca` (adopt existing app on kinto); future updates via `brew upgrade --cask orca`. The unrelated homebrew-core `orca` (plotly image export) is removed where present to free the name.
- Arm/deploy: `chezmoi apply ~/Library/LaunchAgents/dev.onorca.serve.plist && launchctl load ~/Library/LaunchAgents/dev.onorca.serve.plist` (no 1Password: the plist has no secret templates).

## 2026-06-03 -- Removed both io.focused LaunchAgents (migrated to Impulse cron)

- Removed `io.focused.standup-brief.plist` and `io.focused.nightly-health.plist` from chezmoi source (`Library/LaunchAgents/` dir is now empty and removed), plus their `always_on` block in `.chezmoiignore`, plus the deployed copies in `~/Library/LaunchAgents/`.
- Both are now Impulse/Hatchet cron jobs in `dot_config/impulse/jobs.json.tmpl` (kinto branch) per Rai's standing preference (recurring jobs = Impulse, not launchd). See `logs/impulse.md` 2026-06-03 entry for the full job shape + verification.
- standup-brief = enabled (fires Mon-Fri 09:25 BST via the same wrapper). nightly-health = `enabled: false` (stays disarmed; arm by flipping enabled + `pnpm nx run impulse:dev -- sync-crons`).
- The `always_on = ["kinto"]` host group in `.chezmoidata.toml` was left in place for future kinto-only LaunchAgents.

## 2026-06-03 -- nightly-health launchagent is kinto-only

- Added `io.focused.nightly-health.plist` (the Mon-Fri 07:00 system-health + docker-reclaim job; built in ~/focused, OpenSpec change `nightly-system-health`).
- It must deploy ONLY on kinto (the 24/7 Mac Mini with colima + the worktree docker stacks); latios has none of that.
- Mechanism: added host group `always_on = ["kinto"]` to `.chezmoidata.toml`, and guarded the plist in `.chezmoiignore` with `{{ if not (has .chezmoi.hostname .host_groups.always_on) }}` so it is ignored on every host except kinto.
- Reuse `always_on` for future kinto-only launchagents (worktree-janitor, cockpit, discord daemons) when they get chezmoi-ified.
- The plist stays INERT until armed: `chezmoi apply ~/Library/LaunchAgents/io.focused.nightly-health.plist && launchctl load <same>`.
