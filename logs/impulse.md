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
