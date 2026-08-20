# launchagents

Changelog for chezmoi-managed macOS LaunchAgents.

## 2026-08-20 -- Node 24->26 upgrade: unpin 12 LaunchAgents from versioned node path (shims DO work in launchd)

- **Context**: Upgraded global toolchain Node 24.16.0 -> 26.7.0 (asdf). A recon sweep found 12 deployed, non-chezmoi-managed LaunchAgents hardcoding `/Users/rai/.asdf/installs/nodejs/24.16.0/bin/node` in `ProgramArguments` -- every one would break the instant that install is removed. (18 more only carried `24.16.0` as a stale *fallback* PATH entry after a shims-first PATH; those don't break -- a missing PATH dir is skipped -- and were left alone.)
- **Correction to prior belief**: The 2026-08-04 whetstone note (and the plist comments) claimed the asdf shim is "unresolvable in launchd's minimal environment." **This is false.** Three deployed agents already ran on `~/.asdf/shims/node`, and after this change `com.rai.decisions-refresh` was observed running live under launchd on `nodejs/26.7.0/bin/node` via the shim. Shims resolve fine in launchd; the versioned-path workaround was never necessary.
- **Changes** (deployed `~/Library/LaunchAgents/*.plist`, edited directly since none are chezmoi-managed; backups in scratchpad `plist-backup-20260820/`):
  - Swapped `installs/nodejs/24.16.0/bin/node` -> `.asdf/shims/node` (durable, version-independent) in: `ai.openclaw.gateway`, `com.lumiere.ark-discord`, `com.rai.birthday-delivery-monitor`, `com.rai.cli-transcripts`, `com.rai.cortex-mcp`, `com.rai.cortex-health-scan`, `com.rai.decisions-refresh` (two node calls in one `bash -c`, both swapped), `com.rai.dreamcatcher`, `com.rai.quota-usage-recorder`, `com.rai.subagent-extract`, `dev.lumiere.ark.navi`.
  - `com.rai.obsidian-sync-expedition` was **double-pinned** (node binary + `lib/node_modules/obsidian-headless/cli.js` under the versioned dir). obsidian-headless exposes bin `ob`, so collapsed both strings into a single `~/.asdf/shims/ob` invocation -- survives all future node bumps without touching the plist again.
  - Reloaded all via `launchctl bootout` + `bootstrap gui/$UID`. 9 loaded (scheduled jobs idle until trigger; `obsidian-sync-expedition` running on `ob` shim, `decisions-refresh` seen running on node 26).
  - **3 left NOT LOADED on purpose**: `ai.openclaw.gateway`, `com.lumiere.ark-discord`, `dev.lumiere.ark.navi` were already `DISABLED` in launchd's override DB before this work (not running). Their plists are fixed and will use the shim when re-enabled; did not force-enable them.
- **Chezmoi source** (managed, but dormant on this host -- not deployed to `~/Library/LaunchAgents`): `com.rai.whetstone.plist` + `com.rai.whetstone-watchdog.plist` had the same versioned node path (exec + PATH entry). Both bumped to `~/.asdf/shims/node` (exec) and `~/.asdf/shims` (PATH) for the same durability. Source-only edit; not applied.

## 2026-08-04 -- com.rai.whetstone + com.rai.whetstone-watchdog brought under chezmoi (NIMBUS ONLY, staged not applied)

- **Context**: Whetstone (the certification study app) was moved off Cloudflare Workers onto nimbus and served over Tailscale at `https://nimbus.piranha-wyvern.ts.net:8444`. Rai studies from it four hours a day for eight days in Devon from 7 August, with nobody at the machine, so the service and its watchdog had to survive unattended.
- **Problem**: both LaunchAgents existed only in `~/Library/LaunchAgents`. They survive reboots but not a machine rebuild, and an unversioned plist is invisible to review.
- **Changes**:
  - `Library/LaunchAgents/com.rai.whetstone.plist` -- the Next.js standalone server on `127.0.0.1:3011`, `KeepAlive`, logs to `~/.logs/`. Interpreter is the absolute asdf node path because the shim is unresolvable in launchd's minimal environment.
  - `Library/LaunchAgents/com.rai.whetstone-watchdog.plist` -- probes the site every 120s and restarts the service only when the APP is at fault, never when only the tailnet path is.
  - `.chezmoiignore`: both gated behind `{{ if ne .chezmoi.hostname "nimbus" }}`, matching the `dev.onorca.serve` pattern. mondo never sees them.
- **NOT `.tmpl`, deliberately**: neither plist has anything to interpolate, so they are copied verbatim. That also means **neither contains `onepasswordRead`**, so applying them needs no 1Password session -- verified by grep on both.
- **Credentials stay out of the plists**: the service reads `DATABASE_URL`, `AUTH_SECRET`, the GitHub OAuth pair and the five `AUTH_EMAIL_*` SMTP vars at start via node's `--env-file` from gitignored files in the app directory. That decision was made for robustness (rotate a secret, kickstart, done) and it is exactly what makes these plists safe to commit.
- **Staged, NOT applied.** Source and deployed are byte-identical (sha256 verified both files), and `chezmoi status` on both targets is empty, so `chezmoi apply` would be a no-op for them today. Confirmed the check can go the other way by perturbing the source copy alone (`120` -> `121`), seeing `M` reported, then restoring byte-identically.

## 2026-07-23 -- sh.paseo.daemon now execs a wrapper that sources the secret groups

- **Symptom**: `omp` launched via paseo offered only the `anthropic` and `openai-codex` providers. `opencode-zen`, `opencode-go`, `groq` and `zai` were missing.
- **Cause**: launchd hands a job only the vars in the plist's `EnvironmentVariables` dict -- here `HOME` and `PATH`. It never sources a shell, so none of the ~83 exports in `~/.config/zsh/*.zsh` (the chezmoi 1Password secret groups) exist for the daemon or anything it spawns. The two surviving omp providers are exactly the two whose credentials live in omp's HOME-based vault (`auth_credentials` in `~/.omp/agent/agent.db`); every other provider is discovered from env vars alone, so they degraded *silently* rather than erroring. Same class as the PATH-based provider detection the plist header already warned about -- env is the other half of the game.
- **Reproduced**: `env -i HOME=... PATH=<the plist's PATH> omp models` -> `anthropic (25)`, `openai-codex (7)` and nothing else.
- **Changes**:
  - New `bin/executable_paseo-daemon` -> `~/bin/paseo-daemon`: plain `/bin/sh`, sources `~/.config/zsh/*.zsh`, then `exec`s the paseo shim. Args default to `daemon start --foreground` but explicit args win, so it stays testable by hand.
  - `Library/LaunchAgents/sh.paseo.daemon.plist.tmpl`: `ProgramArguments[0]` is now `{{"{{ .chezmoi.homeDir }}"}}/bin/paseo-daemon`; header comment extended with the reasoning.
- **Why a wrapper, not plist env vars**: templating the keys into `EnvironmentVariables` via `onepasswordRead` would put plaintext secrets in a mode-644 file in `~/Library/LaunchAgents`, and would only fix whichever keys someone remembered to enumerate. The wrapper fixes the whole class and keeps the plist secret-free (it still has zero `onepasswordRead`, so `chezmoi apply` on it needs no 1Password session).
- **Not a login shell**, so the powerlevel10k instant-prompt mangling that forced the original direct-exec does not come back. Verified all 10 group files are pure `export NAME=value` -- no zsh-isms, no command substitution -- so `/bin/sh` sourcing is safe.
- **Deploy gotcha**: `launchctl kickstart -k` restarts the job but does **not** re-read the plist -- `launchctl print` still showed the old `program`. Needed a full `launchctl bootout gui/$UID/sh.paseo.daemon` then `launchctl bootstrap gui/$UID ~/Library/LaunchAgents/sh.paseo.daemon.plist`. (The first bootstrap raced the bootout and returned `Input/output error`; an immediate retry succeeded.)
- **Verification**: `launchctl print gui/$UID/sh.paseo.daemon` -> `state = running`, `program = /Users/rai/bin/paseo-daemon`, `last exit code = (never exited)`. `paseo daemon status` -> Local Daemon running, Connected Daemon reachable, relay up on kinto. Sourcing under the launchd-equivalent env restores all six providers, and `amazon-bedrock` stays suppressed even though `AWS_PROFILE=ej-dev` is now in scope (the `disabledProviders` setting from logs/pi.md is HOME-based, so it applies here too).
- **Note**: macOS blocks `ps -E` env dumps, so the daemon's live env can't be read back directly. The proof is the `env -i` harness, which replicates the wrapper's logic exactly, plus `exec` semantics guaranteeing inheritance.

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
