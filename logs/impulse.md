# Impulse XDG Config — Chezmoi Management Log

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
