# Impulse XDG Config — Chezmoi Management Log

## 2026-09-03 -- kinto block becomes latios (Florence -> Tilly)

See `logs/ark.md` 2026-09-03. Every `kinto` branch in `config.json`, `agents.json`,
`jobs.json` and `.env` now targets latios with agent id / namespace `tilly` and
workspace `~/tilly`. Focused-only jobs (jira-sync, standup-brief, nightly-health,
demo-env-refresh) deleted. Hatchet creds move to `op://Private/Hatchet Latios`.

## 2026-07-29 -- Quota producer cutover: OAuth usage endpoint replaces CamoFox as primary (nimbus only)

**Motivation:** bead `workspace-cdkdk`. The CamoFox quota scraper had read
`is_authenticated: false` / `windows: []` / `classification: terminal` for the whole
of 2026-07-29, so every autonomy gate that consults quota proceeded blind. Its chain
has four independent rot points: the CamoFox binary, `~/.camofox/cookies/claude.txt`
expiry, the claude.ai session, and the page shape. Rai found tokenmaxx and asked
whether its method was more resilient; the investigation found something better than
tokenmaxx's undocumented response headers, namely a first-party endpoint,
`GET https://api.anthropic.com/api/oauth/usage`, authenticated with the Claude Code
OAuth token from the macOS Keychain. Same organisation (confirmed via the
`anthropic-organization-id` response header matching the org id in the CamoFox URL),
same field names, so the existing parser and every downstream consumer are unchanged.

**Changed** in `dot_config/impulse/jobs.json.tmpl`, NIMBUS BRANCH ONLY:

- Added `quota-scrape-oauth`, running `libs/claude-quota-scraper/dist/oauth-cli.js`,
  every 5 minutes. It is now the PRIMARY: no `--output` override, so it writes the
  canonical `~/.local/state/impulse/subscription-usage.json` and appends to the
  canonical `scrape-events.jsonl`.
- `quota-scrape` (the CamoFox scraper) is demoted to a SHADOW. It keeps its job id
  and cron, and gains
  `--output=~/.local/state/impulse/subscription-usage-camoufox.json` and
  `--events=~/.local/state/impulse/scrape-events-camoufox.jsonl`.

kinto and the default branch are untouched and still run CamoFox as primary: the
OAuth reader is proven against this machine's keychain and nothing else, and Florence
has her own credentials.

**Why no job was renamed or removed:** adding or deleting a job id would need
`sync-crons --prune` to clear the stale Hatchet cron, and prune deletes any cron whose
job is absent from the DEPLOYED `jobs.json`. There is pre-existing drift there
(`wttj-pipeline-tick` is in the template and not deployed, because it shipped
deliberately unapplied on 2026-07-29 for want of a 1Password session), so a prune would
have deleted a cron that was not mine to touch. Expressing the cutover as an args
change on two jobs that already exist avoids the question entirely. Both ids stay
accurate: `quota-scrape` genuinely IS the CamoFox browser scrape, and the OAuth reader
is not scraping anything.

**Why the two producers get separate `--events` files:** the quota freshness watchdog
treats any recent terminal failure in the event tail as reason to alert the owner.
Leaving both on one file would let the permanently-failing CamoFox shadow raise an
alarm about a perfectly healthy primary. `--events` was added to both CLIs for this.

**Applied:** by hand to `~/.config/impulse/jobs.json`, because `op whoami` reports the
account is not signed in and `chezmoi apply` therefore cannot render the template. The
deployed file and the template carry the identical change and were diffed key by key
after editing, so a later `chezmoi apply` is a no-op for this file.

Then `tsx src/main.ts sync-crons` from `apps/impulse` (required: the cron's stored
input carries the args), and `launchctl kickstart -k gui/501/com.rai.impulse-worker`
so the worker picked up two source changes in `apps/impulse` that it had been running
without for 29 hours.

**Verified live, on the real schedule rather than by kickstart:**

- 20:20:00 the shadow job wrote real numbers to the shadow path while CamoFox wrote
  `windows: []` to the canonical path at 20:20:05, proving the scheduled invocation
  works before anything depended on it.
- 20:25:00 after the cutover, canonical `subscription-usage.json` read
  `source: oauth-usage-api`, `is_authenticated: true`, five_hour 3%, seven_day 60%.
- 20:25:06 CamoFox wrote `account_session_invalid` to the shadow path, still running,
  still not deleted.
- 20:25:35 the restarted worker's blackboard in Postgres read
  `quota.fiveHourPercent 3`, `quota.sevenDayPercent 60`, `quota.usedPercent 60`,
  `quota.level healthy`. Quota is measurable again for the first time that day.

**To revert:** in the nimbus branch of the template, give `quota-scrape` back its bare
`["<home>/dev/lumiere/libs/claude-quota-scraper/dist/cli.js"]` args and give
`quota-scrape-oauth` the `--output`/`--events` shadow overrides (or set it
`"enabled": false`), mirror into `~/.config/impulse/jobs.json`, run `sync-crons`, and
restart the worker. Nothing was deleted, so the old arrangement is a config edit away.

## 2026-07-29 -- Add wttj-pipeline-tick (WTTJ job-application pipeline, shipped disabled)

**Motivation:** bead `workspace-328pb`, child of `workspace-g179l`/`workspace-bgizk` (the WTTJ job-application pipeline, career-critical probation insurance). Four sibling beads had already shipped the pipeline, the phrasing library, the public sourcing adapter, and the Impulse-tick entrypoint itself (`dist/impulse-tick.js`, bead `workspace-s7aos`) — the only missing piece was scheduling it. Design doc: `~/dev/expedition/projects/career/wttj-pipeline-impulse-wiring-design-2026-07-18.md`.

**What changed in `dot_config/impulse/jobs.json.tmpl`:**
- Added one job, `wttj-pipeline-tick`, to the **nimbus** branch only (end of array, after `ark-discord-failed-audio-sweep`). Cron `0 */6 * * *` Europe/London (every 6h, the design doc's proposed default — Rai did not weigh in on cadence before this ticked, so the recommended default was used per the bead's own instruction). `maxConcurrent: 1`, `dedupe: skip-if-running`, `quotaAware: false` (this job gates its own quota internally; the flag is schema-required but unconsumed for `script`-kind targets — checked against `apps/impulse` source, not assumed), `timeout: 1800`.
- Target: `node ~/dev/lumiere/apps/wttj-pipeline/dist/impulse-tick.js` directly, no wrapper script (the entrypoint needs no local-secret loading, unlike `majora-gatekeeper.sh`). `inputs.cwd` set to the app directory — deliberately, so the entrypoint's own default state-dir resolution (`./state/wttj-pipeline` relative to cwd) lands on the exact absolute path `recap-health-monitor.mjs`'s existing WTTJ guard (`workspace-zn6mb`) already hardcodes. No `WTTJ_PIPELINE_STATE_DIR` override anywhere, by design.
- **`enabled: false`.** `WTTJ_PIPELINE_ENABLED` (the app-level env gate) also remains unset everywhere. Both are deliberate, belt-and-suspenders (Rule 57) — this is the single decision that takes WTTJ live, and it stays Rai's.
- No other job touched. kinto and the fallback branch unchanged.

**Cadence/guard coupling checked, not assumed:** `recap-health-monitor.mjs`'s `WTTJ_PIPELINE_CADENCE_MS` constant is `6 * 60 * 60 * 1000` — matches the landed cadence exactly, so that file needed no edit. Recorded on the bead and in `wttj-pipeline-STATE.md` so the arithmetic is on record rather than trusted.

**NOT deployed.** Source only. `chezmoi execute-template` renders and parses (30 jobs on nimbus); a target-scoped `chezmoi diff -- ~/.config/impulse/jobs.json` shows exactly this one addition and nothing else (`chezmoi diff` with no target failed on an unrelated file's expired 1Password read — `dot_aider.conf.yml.tmpl` — so the diff was scoped instead of skipped). A full `chezmoi apply` was not attempted: `op whoami` reports "account is not signed in" despite `op account list` succeeding (that command lists configured accounts and needs no live session — verified the distinction before trusting it), so no session is actually active.

## 2026-07-28 -- Add ark-discord-failed-audio-sweep (7-day retention on preserved voice audio)

**Motivation:** On 2026-07-28 a long voice utterance died to a local STT timer and was unrecoverable by construction — the audio had been streamed to Cartesia and the buffer released. Rai decided on voice at 18:31 BST that any audio which FAILS is preserved on disk for 7 days and then cleaned up, verbatim: *"it should never happen that we can't just regenerate from my audio."* The ark-discord daemon now preserves that audio (bead `workspace-ccxq7`, lumiere commit `2bfb8ade`).

The daemon sweeps expired files at startup and every 6h, but the DELETE half of the decision is a privacy promise and has to hold when the daemon is dead. A retention policy that only runs when everything is fine is not a retention policy, so the same sweep also runs out of process. Impulse cron rather than a new launchd agent, per hot.md Rule 65.

**What changed in `dot_config/impulse/jobs.json.tmpl`:**
- Added one job, `ark-discord-failed-audio-sweep`, to the **nimbus** branch only. Daily cron `10 4 * * *` Europe/London (`trigger.kind: "cron"` — `"interval"` has no execution path), `maxConcurrent: 1`, `dedupe: skip-if-running`, `quotaAware: false`, `enabled: true`.
- Target: `node ~/dev/lumiere/apps/ark-discord/dist/failed-audio-retention-cli.js`. Same `sweepFailedAudio` the daemon calls — one implementation, two independent triggers, deliberately not a second copy of the retention rule.
- No other job touched. kinto and the fallback branch unchanged.

**NOT deployed.** Source only. `chezmoi execute-template` renders and parses (29 jobs); `chezmoi diff ~/.config/impulse/jobs.json` shows this addition and nothing else. A full `chezmoi apply` was not possible — `chezmoi status` errors on a 1Password authorization timeout, so no `op` session was live.

⚠️ **Ordering matters on deploy:** the job points at a `dist/` artifact that does not exist until `nx build ark-discord` has run. Apply it AFTER the build, or it errors nightly until then.

## 2026-07-21 -- Give Majora canary and repair runs enough scheduler headroom

**Motivation:** The redesigned OpenAI-only Majora engine completed its accepted live canary in five minutes, while a bounded timeout/retry can legitimately exceed the previous 600-second Impulse job limit. A scheduler kill would strand the vault lock until stale-lock recovery and turn a valid repair pass into an operational failure.

**What changed in `dot_config/impulse/jobs.json.tmpl`:**
- Raised only the `majora-research-engine` job timeout from 600 to 900 seconds.
- Kept `maxConcurrent: 1` and `dedupe: skip-if-running`; the 15-minute ceiling remains below the engine's 20-minute stale-lock TTL.
- Applied the single plain-config target and re-synced the existing Hatchet cron; no other Impulse job changed.

## 2026-06-20 -- Remove session-recap-tick job (recap retired)

**Motivation:** The `/recap` HTTP endpoint and `recap-cli.ts` producer were removed from discord-text-plugin (chore/retire-recap). The prose-mirror accumulator is now the sole transcript-to-Discord path. The `session-recap-tick` Impulse cron job was the producer for the now-deleted endpoint.

**What changed in `dot_config/impulse/jobs.json.tmpl`:**
- Removed `session-recap-tick` job object from the kinto branch (was hourly cron, `enabled: true`).
- Removed `session-recap-tick` job object from the nimbus branch (was every 10m cron, `enabled: true`).

**Deployed:** job already disabled (enabled:false) in the deployed `/Users/rai/.config/impulse/jobs.json` on nimbus; entire object now removed from the template. sync-crons --prune run to confirm no stale Hatchet crons remain.

## 2026-06-03 -- Add Florence daily-blog Impulse job (bead focused-9fia)

**Motivation:** Florence's daily blog automation, modeled on Navi's journal pipeline (same `ark run <agent>` -> skill-mode shape). Rai's standing rule (bd memory `scheduled-recurring-jobs-on-kinto-impulse-jobs-hatchet`): recurring jobs on kinto = Impulse/Hatchet cron, NOT launchd. The blueprint (`~/focused/vault/References/Florence Daily Blog.md`) originally suggested launchd; explicitly overridden to Impulse to match Navi.

**What changed in `dot_config/impulse/jobs.json.tmpl` (kinto branch):**
- Added job `daily-blog` (enabled): cron `30 21 * * *` Europe/London (21:30 BST, after lamplight nightly digest at 22:00 is fine since the post reads breadcrumb + transcripts which are current by then), `target.kind: ark-spawn`, agent `florence`, model `opus`, `maxTurns: 40`, `timeout: 2700`, `dedupe: skip-if-running`, tags work/kinto/blog.
- Carries both `promptFile: prompts/florence-daily-blog.md` (Navi-parity) and an inline `inputs.prompt` (the live ark-spawn workflow factory reads `inputs.prompt`, so the inline copy is what actually runs). The prompt is a thin launcher: read `~/focused/.claude/skills/daily-blog/SKILL.md`, pick mode by day-of-week (`date +%u`; Mon-Fri weekday-post, Sat-Sun weekend-post), write to `~/focused/vault/Blog/`, DM Rai on Discord (chat_id 1499031021746913341).

**New file:** `dot_config/impulse/prompts/florence-daily-blog.md` (thin launcher, mirrors Navi's `journal-full-post.md` shape).

**The skill itself** lives in the focused repo at `~/focused/.claude/skills/daily-blog/` (SKILL.md router + persona.md/voice-and-spine.md/research-step.md/weekend-wild.md references), committed separately to focused.

**Registration flow (done):** edited chezmoi source -> `chezmoi apply ~/.config/impulse/jobs.json ~/.config/impulse/prompts/florence-daily-blog.md` (no onepasswordRead in these targets, so no 1Password session needed) -> `pnpm nx run impulse:dev -- sync-crons`.

**Verification:** `list-jobs` shows `daily-blog` enabled. `sync-crons` registered `florence/daily-blog -> 30 20 * * * UTC` (= 21:30 BST). Worker `dev.lumiere.impulse-florence` is running (launchd keepalive, state=running). The job is ARMED: it will fire nightly at 21:30 BST starting tonight. First auto-run is reviewable (it writes the post AND DMs Rai; if voice is off, iterate on the skill refs). A dry-run sample post #2 was hand-generated to `~/focused/vault/Blog/daily-blog-SAMPLE.md` (Wednesday = weekday-post) before arming.

## 2026-06-03 -- Migrated standup-brief + nightly-health from launchd to Impulse cron jobs

**Motivation:** Rai's standing preference (bd memory `scheduled-recurring-jobs-on-kinto-impulse-jobs-hatchet`): recurring jobs on kinto = Impulse/Hatchet cron entries, not launchd LaunchAgents. Two jobs were still launchd plists.

**What changed in `dot_config/impulse/jobs.json.tmpl` (kinto branch):**

- Added job `standup-brief` (enabled): cron `25 9 * * 1-5` Europe/London, `target.kind: script`, runs `bash {{ .chezmoi.homeDir }}/focused/scripts/standup-brief/standup-brief.sh` (the SAME wrapper the launchd job used; it loads the whisper token + ark port, checks readyz, then `ark whisper command /standup-brief`). `inputs` carries cmd/args/cwd for the `impulse-script` workflow factory.
- Added job `nightly-health` (enabled: false -- DISARMED): cron `0 7 * * 1-5`, runs `bash {{ .chezmoi.homeDir }}/focused/scripts/health/nightly-health.sh`. Stays INERT because sync-crons + the worker both filter on `enabled`; a disabled job gets NO Hatchet cron and is pruned if previously synced. Rai arms it later by flipping `enabled: true` and re-running sync-crons (no chezmoi/launchd dance).

**Job entry shape (learned):** each entry needs `id`, `name`, `trigger` (cron expr + tz), `target` (`{kind: script, bin}` for shell jobs, or `ark-spawn` for prompts), `payload` (`{kind: shell, cmd, args}` descriptor), `policy` (maxConcurrent/quotaAware/dedupe, optional timeout secs), `enabled`, optional `tags`, and `inputs` -- the runtime block the generic workflow factory actually reads (`cmd`, `args`, `cwd`, optional `env`). Script jobs all share the `impulse-script` Hatchet task (runners.ts spawns cmd/args in cwd; non-zero exit = step failure).

**Registration flow:** edit chezmoi source -> `chezmoi apply ~/.config/impulse/jobs.json` -> `pnpm nx run impulse:dev -- sync-crons` (registers `<namespace>/<job.id>` crons into Hatchet, converting Europe/London to UTC). The long-running worker `dev.lumiere.impulse-florence` executes them.

**Verification:** `list-jobs` shows standup-brief enabled / nightly-health disabled. Hatchet postgres `WorkflowTriggerCronRef` has `florence/standup-brief | 25 8 * * 1-5` (UTC = 09:25 BST), nightly-health correctly absent. `trigger standup-brief` (STANDUP_DRY_RUN=1) ran the wrapper end to end: exitCode 0, session ready, would-whisper confirmed. standup-brief WILL fire 2026-06-04 09:25 BST.

**Removed:** both launchd plists (`io.focused.standup-brief.plist`, `io.focused.nightly-health.plist`) from chezmoi source `Library/LaunchAgents/` (dir now empty, removed), plus their `.chezmoiignore` `always_on` conditional block, plus the deployed copies in `~/Library/LaunchAgents/` (standup-brief unloaded first; nightly-health was never loaded). The `always_on = ["kinto"]` host group in `.chezmoidata.toml` is left in place for future kinto-only use.

## 2026-05-02 — Initial chezmoi management of ~/.config/impulse/

**Motivation:** Impulse's XDG config directory (`~/.config/impulse/`) was unmanaged. Adding it to chezmoi ensures config is reproducible across machines and version-controlled with proper secret management.

**What was added:**

- `dot_config/impulse/dot_env.tmpl` — Environment variables for the Impulse worker. Includes Hatchet connection config (host-specific nimbus/default branches), scheduler paths (templated with `chezmoi.homeDir`), Discord token via `onepasswordRead`, narrate pipeline config, temperature sensor IDs, and Claude Code OAuth token (using the same shared-oauth conditional as `dot_zshenv.tmpl`).
- `dot_config/impulse/config.json.tmpl` — Host-specific runtime config. Nimbus gets full capabilities enabled (cron, sensors, heartbeats, narrate queue, stewardship, openclaw probe); other hosts get all capabilities disabled with templated paths.
- `dot_config/impulse/agents.json.tmpl` — Agent registry (navi, shikamaru, heimerdinger, hermione, rick). Copied from `~/dev/lumiere/apps/impulse/config/agents.json`. Same across all hosts; no conditionals needed currently.
- `dot_config/impulse/jobs.json.tmpl` — Cron job definitions. Nimbus gets the full 20-job list (dossier refresh, weekly memory/continuity, journal pipeline, cortex ticks, openclaw agent ticks, narrate). Other hosts get an empty array.
- `dot_config/impulse/prompts/` — 13 static `.md` prompt files copied verbatim from `~/.config/impulse/prompts/`. No templates needed.
- `dot_config/impulse/scripts/executable_dossier-cycle.sh` — Shell script for dossier refresh job. Uses `executable_` prefix for chezmoi to deploy with +x permission.

**1Password integration:**

- `OPENCLAW_DISCORD_NAVI` → `op://Private/Navi Discord tokens/credential` (found in `dot_zshenv.tmpl` line 117)
- `CLAUDE_CODE_OAUTH_TOKEN` → `op://focused/claude code oauth token/credential` or `op://Private/Anthropic/Saved on console.anthropic.com/token` (conditional, matches `dot_zshenv.tmpl` lines 149-154)
- `HATCHET_CLIENT_TOKEN` and `HATCHET_CLIENT_TENANT_ID` — **NOT in 1Password**. These are locally-generated JWT tokens for the self-hosted Hatchet instance. Placeholder values set; TODO to store in 1Password at `op://Private/Hatchet Nimbus/{token,tenant_id}`.

**Template validation:**

- `config.json.tmpl`: renders valid JSON, nimbus branch produces correct nimbus-specific config.
- `agents.json.tmpl`: renders valid JSON with all 5 agents.
- `jobs.json.tmpl`: renders valid JSON with all 20 nimbus jobs.
- `dot_env.tmpl`: template syntax correct (cannot fully render without 1Password session for `onepasswordRead` calls).

**Not done:**

- `chezmoi apply` not run (requires active 1Password session).
- Hatchet credentials need to be stored in 1Password before the `.env` template will produce working values on nimbus.

## 2026-05-10 — Fix journal job enablement gap in jobs.json.tmpl

### Problem

All 7 journal pipeline jobs (`journal-draft-init`, `journal-morning-catchup`, `journal-hourly-append`, `journal-late-start-recovery`, `journal-title-pass`, `journal-full-post`, `journal-weekly-post`) were set to `"enabled": false` in the template, causing a 32-hour blackout of journal posts on nimbus (May 2-5).

Additionally, a stash conflict existed: the deployed `~/.config/impulse/jobs.json` had 6 additional jobs enabled (`dream-sources-seed`, `expedition-calibration`, `cortex-tick`, `cortex-review-tick`, `narrate-daily`, `narrate-weekly`) that the template had as `false`. Applying the template without fixing this would have reverted those 6 jobs.

### Solution/Fix

- Set `"enabled": true` for all 7 journal pipeline jobs in `dot_config/impulse/jobs.json.tmpl`.
- Also set `"enabled": true` for the 6 additional jobs that were already enabled in the deployed file, syncing template to deployed state.
- Jobs intentionally left disabled: `dossier-refresh`, `weekly-memory-maintenance`, `weekly-continuity-review`, `shikamaru-dart-tick`, `heimerdinger-dart-tick`, `hermione-dart-tick`, `rick-dart-tick`.
- `chezmoi apply` not run — no 1Password session active. Rai needs to run `eval $(op signin --account personal)` then `chezmoi apply ~/.config/impulse/jobs.json` to deploy. Remaining diff is cosmetic formatting only (no enabled values change).

## 2026-05-10 — Add journal-gap-check job and full-post resilience note

### Problem

The 21:00-21:10 BST journal finalization window (title-pass + full-post) is frequently missed when the Impulse worker crashes. There was no recovery mechanism — if the worker came back at 23:44 (as on May 8), the cron window had passed and the post was simply lost.

### Solution/Fix

- Added a new `journal-gap-check` job to `dot_config/impulse/jobs.json.tmpl` (cron `0 23 * * *`, Europe/London, ark-spawn, navi, sonnet, `enabled: true`, tags: journal-pipeline/nimbus, maxTurns: 40).
- Also deployed the same job to the live `~/.config/impulse/jobs.json` for immediate effect before next `chezmoi apply`.
- Created new prompt file at `dot_config/impulse/prompts/journal-gap-check.md` (and live `~/.config/impulse/prompts/journal-gap-check.md`). The prompt checks for a titled post (YYYY-MM-DD Title.md in ~/dev/expedition/blog/); if missing but draft exists, runs title-pass then full-post sequentially.
- Added a resilience note to `dot_config/impulse/prompts/journal-full-post.md` (and live equivalent): before writing, check whether the titled file exists; if not, run title-pass first. Guards against the independent cron race condition where full-post fires before title-pass completes.
- `chezmoi apply` not run — no 1Password session active. Deployed files were edited directly for immediate effect.

## 2026-05-15 — Add host-branching for agents.json template (superseded by kinto/florence)

### Problem

`agents.json.tmpl` shipped nimbus-specific OpenClaw agent definitions to ALL hosts. Work machines should not receive OpenClaw agents.

### Solution/Fix

- Originally added `host_groups.work` → flaude branch, but this was superseded by the 2026-05-21 kinto/florence work (below).
- Final template uses hostname-specific branching: `kinto` → florence, `nimbus` → navi + openclaw agents, `else` → empty array.

## 2026-05-21 — Add kinto (Florence) support across all Impulse templates

### Motivation

Kinto is a Mac Mini that runs Florence (work-Claude agent), separate from Nimbus which runs Navi (personal agent). Kinto was already in the `work` host group in `.chezmoidata.toml` but had no Impulse-specific template branches.

### Changes

**`config.json.tmpl`:**
- Added `kinto` branch in the hatchet section: namespace "florence", workerName "impulse-kinto".
- Added `kinto` branch in capabilities: cronEnabled, sensorsEnabled, heartbeatsEnabled = true; narrateQueueEnabled, stewardshipEnabled, openclawProbeEnabled = false.
- workspaceRoot already resolves to `~/focused` via the existing `host_groups.work` conditional.

**`dot_env.tmpl`:**
- Added `kinto` branch for Hatchet credentials from `op://focused/Hatchet Kinto/{token,tenant_id}` (port 18888/17077, matching nimbus docker mapping).
- Added `kinto` branch for scheduler paths: `ARK_WORKSPACE`, `FLORENCE_SCHEDULER_STATE_ROOT`, `FLORENCE_SCHEDULER_LOG_LEVEL`, `FLORENCE_SCHEDULER_NAMESPACE`.
- Added `kinto` branch for Discord: `FLORENCE_DISCORD_TOKEN` from `op://focused/Flaude Discord/credential`.
- Wrapped nimbus-only sections (narrate pipeline, temperature sensor) in `nimbus` conditional so they don't render on kinto.
- `CLAUDE_CODE_OAUTH_TOKEN` already handled by the `shared_claude_oauth` / `host_groups.work` conditional.

**`agents.json.tmpl`:**
- Added `kinto` branch with a single florence agent (adapter: ark, strategy: WORK, all optional features disabled).
- Non-kinto hosts fall through to existing nimbus agents (navi, shikamaru, heimerdinger, hermione, rick).

**`jobs.json.tmpl`:**
- Added `kinto` branch with 3 jobs: quota-scrape (every 5m, script), morning-sweep (08:30 daily, ark-spawn florence), jira-sync (08:00 daily, ark-spawn florence).
- Nimbus jobs unchanged, other hosts still get quota-scrape only.

**`../ark/config.json.tmpl`:**
- Renamed work account cookiesPath from `flaude.txt` to `florence.txt`.

### Not done

- `chezmoi apply` not run. Templates are source-only edits.
- The actual `~/.camofox/cookies/florence.txt` file needs to exist on kinto (renamed from flaude.txt or re-exported).

## 2026-05-24 — Fix scheduler/Discord sections to use host_groups.work instead of hardcoded kinto

### Problem

The scheduler paths section (line 28) and the Discord section (line 42) of `dot_env.tmpl` used `{{- if eq .chezmoi.hostname "kinto" }}` — hardcoded to the kinto hostname. This meant the Florence scheduler config and Discord token would not render on any future work host (e.g. latios) even though it was already in `host_groups.work`.

### Fix

Changed both `{{- if eq .chezmoi.hostname "kinto" }}` occurrences in the scheduler and Discord sections to `{{- if has .chezmoi.hostname .host_groups.work }}`. This matches the pattern already used at line 64 (Claude OAuth conditional) and in other templates.

The Hatchet section (lines 9-24) retains the explicit `kinto` hostname branch — it references kinto-specific 1Password credentials and should not be generalised until other work hosts have their own Hatchet items.

### Not done

- `chezmoi apply` not run. Template is source-only.

## 2026-05-25 — chezmoi template sync: proactiveMiningEnabled

**Problem:** proactiveMiningEnabled was added to deployed agents.json on nimbus (May 24, during proactive thread-mining cascade deployment) but the chezmoi source template was not updated. Next `chezmoi apply` would have reverted the flag.

**Fix:** Added `"proactiveMiningEnabled": true` to Navi's agent entry in `dot_config/impulse/agents.json.tmpl` (nimbus block only). Florence on kinto doesn't use proactive mining. Verified: template output matches deployed config exactly after edit.

## 2026-06-03 -- lamplight nightly 22:00 -> 21:00

Moved `lamplight-nightly` from `0 22` to `0 21` (Europe/London) so the full daily digest lands before the daily-blog job at 21:30 (blog reads lamplight Summary). 30-min buffer; blog tolerates a stale/missing Summary anyway. Applied + sync-crons re-registered (florence/lamplight-nightly -> 0 20 UTC).

## 2026-06-09 -- Monthly ChatGPT Pro invoice -> Focused expense job

### Problem
Rai needs his ChatGPT Pro invoice (GBP 200/mo) submitted to Focused Labs expenses monthly. OpenAI does NOT email receipts (unlike his other Stripe-billed tools), so the invoice only lives in the ChatGPT billing portal (authenticated). He asked for an Impulse job (ark-spawn) on the 1st of each month, chezmoi-defined.

### Solution/Fix
- Added job `chatgpt-invoice-monthly` to the nimbus branch of `dot_config/impulse/jobs.json.tmpl` (cron `0 9 1 * *` Europe/London, target ark-spawn navi/sonnet, enabled, promptFile).
- New prompt `dot_config/impulse/prompts/chatgpt-invoice-monthly.md`: opens ChatGPT billing via opentabs (launches Chrome itself if closed -- not a blocker, Navi has sudo + automation-mcp), grabs the latest invoice URL, runs the helper script.
- Helper (in navi repo): `~/navi/bin/chatgpt-invoice-email.mjs` resolves the official itemised PDF via Stripe's `invoicedata.stripe.com/invoice_pdf_file_url/<acct>/<token>` endpoint -> signed S3 PDF, then gog-emails it to rai.butera@focused.io with the Rippling link.
- Verified template <-> deployed in sync (chezmoi cat == deployed, 24 jobs) before adding; applied -> 25 jobs deployed. No secrets in the template, applied without 1Password.

## 2026-06-20 -- Temporarily disable Cortex Tick + Cortex Review Tick

### Problem
Rai is not actively using Cortex right now. The two scheduled Cortex jobs (`cortex-tick` every 20m, `cortex-review-tick` hourly) spawn ephemeral headless Navi sessions (`target.kind: ark-spawn`) that run do-tick/do-review against the bead+Cortex work surface. This (a) confused Rai ("are there two Navis running?"), (b) caused a near-collision with the main session's Continue roll on bead workspace-ezfr (both claimed it ~1 min apart), and (c) added ephemeral-session prose to his Discord notification flood.

### Solution/Fix
Set `enabled: false` for `cortex-tick` and `cortex-review-tick` in BOTH:
- deployed `~/.config/impulse/jobs.json` (live — read by sync-crons)
- source `dot_config/impulse/jobs.json.tmpl` (so a future `chezmoi apply` keeps them disabled; template is onepasswordRead-free so safe to apply once the wider deployed-vs-template drift is reconciled)
Then ran `tsx src/main.ts sync-crons --prune` from `apps/impulse` → pruned both crons from Hatchet (confirmed: "pruning stale cron: navi/cortex-tick", "navi/cortex-review-tick").

To RE-ENABLE later: flip both back to `enabled: true` in deployed jobs.json, re-run `sync-crons` (no --prune needed to add).

### Known drift (flagged for the dotfiles conversation)
Deployed jobs.json and the chezmoi template have diverged BOTH ways: deployed has narrate-*/journal-* set + the quota-scrape path fix; template has an older set (jira-sync, lamplight-*, morning-sweep, standup-brief, daily-blog, nightly-health, todoist-hygiene) that is NOT deployed. "Which is canonical" is unresolved — do NOT `chezmoi apply` the template wholesale or it will regress the deployed set. Cortex disable was applied to both so it survives either resolution.
## 2026-07-28 — cold-mode roll interval 60min → 15min (Rai request, reverting the 2026-07-22 quota change)
Rai (Discord, 14:58): *"we should retune the impulse dice rolls back down to every 15min in cold mode"*. Set navi's `coldModeIntervalMs` in `dot_config/impulse/agents.json.tmpl` from `3600000` (60min) → `900000` (15min), reverting the 2026-07-22 entry below. Applied with `chezmoi apply ~/.config/impulse/agents.json`, restarted `com.rai.impulse-worker` (`launchctl kickstart -k`). Verified live in `apps/impulse/logs/worker.stderr.log`: `Cold-mode heartbeat registered for agent: navi (base interval: 900s, exhaustion-throttle: disabled)` at 15:02:19, where the three preceding restarts all read `3600s`. Other agents untouched at 1200000 (20min).

⚠️ The 2026-07-22 change was made because weekly quota was at 84%. **That reason could NOT be re-checked before reverting**: `~/navi/state/subscription-usage.json` shows `windows: []`, `is_authenticated: false`, `degraded: ["scrape_failed"]`, `error: account_session_invalid` with `scraped_at` an hour old — the camoufox cookies are expired (known shape, needs Rai's browser re-auth). So the honest statement is *quota is unmeasurable right now*, NOT *quota is fine*. Rai owns the quota and asked for the change, so it was made; but the sensor that would warn him it was a mistake is blind, and `exhaustion-throttle: disabled` means 15min is a hard floor with no automatic widening. To revert: set the value back to `3600000`, apply, restart the worker.

## 2026-07-22 — cold-mode roll interval 15min → 60min (Rai request, quota)
Rai (Discord): "increase the impulse wild personal etc rolls interval to every 60 min in cold mode? I don't have much quota left" (weekly at 84% used, ~64% through the window). Changed navi's `coldModeIntervalMs` in `dot_config/impulse/agents.json.tmpl` from `900000` (15min) → `3600000` (60min). Applied via `chezmoi apply ~/.config/impulse/agents.json`, restarted `com.rai.impulse-worker` (launchctl kickstart -k). Verified live: worker log `Cold-mode heartbeat registered for agent: navi (base interval: 3600s)`. The quota modulator still stretches it longer when weekly is high — 60min is now the FLOOR, not a cap. Other agents (shikamaru/heimerdinger/etc) left at 1200000 (20min). To revert: set navi's value back to 900000 in the template, apply, restart the worker.

## 2026-08-06 -- Navi dice cadence 60m -> 30m

### Problem
Rai bought a second Claude account (more weekly quota headroom) and asked to raise Navi's cold-mode dice-roll cadence from every 60m back down to every 30m, to push harder on Rennet + the WTTJ pipeline. (Yesterday it had been dropped 900000->3600000 to conserve quota; that constraint has eased.)

### Solution/Fix
Edited source `dot_config/impulse/agents.json.tmpl`, nimbus branch, agentId "navi": `coldModeIntervalMs` 3600000 -> 1800000 (30 min). Only navi/nimbus touched; shikamaru/heimerdinger/hermione/rick untouched. No onepasswordRead in the file, so applied without a 1P session. `chezmoi apply ~/.config/impulse/agents.json`, then `launchctl kickstart -k gui/501/com.rai.impulse-worker`. Verified LOADED in the running process (not just deployed): worker.stderr.log registration line at 10:55:37 reads `base interval: 1800s` (new pid 93474), history 900s->3600s->1800s.

## 2026-09-04 -- Add deadline-radar cron (nimbus)

### Problem
The new /navi/deadlines dashboard panel (bead workspace-kss3l) reads a host-produced scan file (~/navi/state/deadline-radar.json). Nothing refreshed it on a schedule, so freshness would decay to could-not-check after 90 min.

### Solution/Fix
Added job id `deadline-radar` to `dot_config/impulse/jobs.json.tmpl` nimbus branch AND the deployed `~/.config/impulse/jobs.json` (kept in sync): cron `*/30 * * * *` Europe/London, target/payload kind script. Command is a secret-free wrapper `zsh -c 'source ~/.config/zsh/tools.zsh 2>/dev/null; exec node ~/navi/bin/deadline-radar-scan.mjs'` -- sourcing tools.zsh gives the child GOG_KEYRING_PASSWORD + TODOIST_API_TOKEN (both plain exports there) so calendar+Todoist read, with NO secret in git or the job file. Producer degrades per-source to could-not-check on any missing env, so worst case is beads-only. No `chezmoi apply` (needs 1P session); deployed copy written directly so it is live for the next worker sync-crons. To register in Hatchet now: restart com.rai.impulse-worker (run-worker.sh runs sync-crons on start).
