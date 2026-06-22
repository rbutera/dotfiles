# Claude Code config changes log

## 2026-06-22 — Verified entitlement-cache scrub is STILL needed (keep it)

### Context
While reconciling chezmoi drift, `.claude.json` kept showing as drifted right
after `chezmoi apply`. Questioned whether the `modify_dot_claude.json.tmpl`
entitlement-cache scrub (`del(.cachedExtraUsageDisabledReason)` + 4 siblings,
added 2026-04-12 for the `/model opus[1m]` gate bug #45449) was now obsolete on
Opus 4.8.

### Finding — NOT obsolete, do not remove
- **Issue [#45449] is closed as NOT_PLANNED** — auto-closed by the
  github-actions bot for inactivity ("Closing for now — inactive for too long"),
  **not** because it was fixed. No fix shipped; last human comment just restates
  the env-var workaround.
- **Live machine is still being re-poisoned.** Applied `.claude.json` (scrub
  deletes the keys), then `jq` on `~/.claude.json` showed
  `cachedExtraUsageDisabledReason: true` back, plus `hasAvailableSubscription`,
  `s1mAccessCache`, `passesEligibilityCache`, `clientDataCache` all repopulated.
  So Claude Code re-writes the poisoned keys at runtime between applies.

### Conclusion
The scrub is actively doing its job; removing it would re-break
`/model opus[1m]`. **Keep both** the scrub and `ANTHROPIC_DEFAULT_OPUS_MODEL`.
This re-poisoning is also the root cause of `.claude.json`'s perpetual drift —
expected and benign (a `modify_` script over a runtime-churned file will always
diff). Track [#45449] for an eventual real fix before removing either workaround.

[#45449]: https://github.com/anthropics/claude-code/issues/45449

## 2026-06-03 — Re-add Opus model pin as 4.8, conditional on host group

### Problem

The Opus 4.6 model pin was removed on 2026-06-01 but the value persisted in all shells via tmux's global environment (the tmux server was started when the old export was still active). Re-adding the pin as Opus 4.8 with a host-group conditional: work machines (`latios`, `kinto`) get `claude-opus-4-8[1m]` (1M context), others get `claude-opus-4-8`.

### Changes

- **`dot_zshenv.tmpl`**: Added conditional `ANTHROPIC_DEFAULT_OPUS_MODEL` export under the Claude Code section — `claude-opus-4-8[1m]` for `host_groups.work`, `claude-opus-4-8` for others.
- **tmux global env**: Updated stale `ANTHROPIC_DEFAULT_OPUS_MODEL` from `claude-opus-4-6[1m]` to `claude-opus-4-8[1m]` via `tmux set-environment -g`.

## 2026-06-01 — Remove Opus 4.6 model pin

### Problem

`ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-6[1m]'` was set as a workaround for the `/model opus[1m]` client-side gate bug (anthropics/claude-code#45449). With Opus 4.8 released and the upstream bug long resolved, the pin was preventing adoption of newer Opus models.

### Changes

- **`dot_zshenv.tmpl`**: Removed `export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-6[1m]'` and its comment block.
- **`Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`**: Removed the mirrored `$env:ANTHROPIC_DEFAULT_OPUS_MODEL` line.

## 2026-05-08 — Replace Perplexity MCP with Exa (HTTP mode)

### Problem

Switching from Perplexity MCP to Exa MCP for web search across Claude Code and Codex CLI.

### Changes

- **`modify_dot_claude.json.tmpl`**: Removed `perplexity` npx entry from the heredoc. Added a post-heredoc jq step that injects `exa` as an HTTP MCP server (`{"type": "http", "url": "https://mcp.exa.ai/mcp?enableAdvancedSearch=true", "headers": {"x-api-key": ...}}`). The `type` field is required by Claude Code's schema for HTTP transport. API key read from `$EXA_API_KEY` at apply time — no 1Password dependency in this script.
- **`dot_codex/modify_private_config.toml`**: Replaced `perplexity` (zsh/npx command) with `exa` using HTTP mode (`url` + `headers`), API key read from `os.environ.get("EXA_API_KEY")` at apply time.
- `EXA_API_KEY` was already exported in `dot_zshenv.tmpl` (line 134, via `op://Private/EXA API Key/credential`).

## 2026-05-08 — Raise skill budget, disable unused plugins

### Problem

Skill listing was truncated at startup — 70 descriptions dropped at 1% budget. Plugins like slack, plugin-dev, and mcp-server-dev contribute 12 skills that are irrelevant for most sessions.

### Changes

- **`dot_claude/modify_settings.json`**: Set `skillListingBudgetFraction` to 0.02 (2%, ~6k tokens). Removed `plugin-dev`, `mcp-server-dev`, `slack` from the base `enabledPlugins`. Added `del()` in the jq merge to actively strip these three plugins from existing settings on apply.

## 2026-04-29 — Add shared OAuth toggle

### Problem

The Claude Code OAuth selection needed a repo-level switch so the same credential source can optionally be used across machines without changing host group membership.

### Changes

- **`.chezmoidata.toml`**: Added `feature_flags.shared_claude_oauth` as a repo-level switch.
- **`dot_zshenv.tmpl`**: Claude Code OAuth selection now uses the shared flag or the existing host group match.

## 2026-04-29 — Restore host-aware OAuth token selection

### Problem

`CLAUDE_CODE_OAUTH_TOKEN` had been removed from `dot_zshenv.tmpl`, but the environment still needs host-aware Claude Code OAuth credential selection.

### Changes

- **`dot_zshenv.tmpl`**: Restored the `CLAUDE_CODE_OAUTH_TOKEN` host group conditional:
  - matching hosts read the grouped credential source
  - all other hosts read the default credential source

## 2026-04-26 — Enable computer-use MCP across all Claude projects

### Problem

The `computer-use` built-in MCP server is disabled by default in Claude Code and must be opted in per-project via `.projects[path].enabledMcpServers` in `~/.claude.json`. Manually enabling it for each project is tedious.

### Changes

- **`modify_dot_claude.json.tmpl`**: Extended the jq transform to iterate all entries in `.projects` and merge `["computer-use"]` into each project's `enabledMcpServers` array (with `unique` dedup). Runs on every `chezmoi apply`, so new projects pick it up automatically.

## 2026-04-24 — Remove all stale Claude auth tokens from zshenv

### Problem

Claude Code CLI was potentially misidentifying the auth mode (API key vs Max subscription) despite valid OAuth credentials in `~/.claude/.credentials.json` showing `subscriptionType: "max"`. Multiple shell-exported tokens from 1Password — `CLAUDE_CODE_TOKEN`, `ANTHROPIC_CLAUDE_CODE_TOKEN`, and `CLAUDE_CODE_OAUTH_TOKEN` — could conflict with the proper credential file auth flow managed by `claude auth login`.

### Changes

- **`dot_zshenv.tmpl`**: Removed `CLAUDE_CODE_TOKEN`, `ANTHROPIC_CLAUDE_CODE_TOKEN`, and `CLAUDE_CODE_OAUTH_TOKEN` (both work and personal variants). Authentication is handled by `claude auth login` which stores tokens in `~/.claude/.credentials.json` — the env vars were unnecessary and potentially interfering with `getAuthTokenSource()`.

## 2026-04-24 — Switch automation MCP from HTTP to stdio

### Problem
The automation MCP server on nimbus was configured as an HTTP streaming connection (`http://localhost:3010/stream`), requiring the server to be running independently before Claude Code could connect.

### Changes

**`modify_dot_claude.json.tmpl`**:
- Changed automation MCP from `{"type": "http", "url": "http://localhost:3010/stream"}` to a stdio command: `bun run /Users/rai/dev/github/ashwwwin/automation-mcp/index.ts --stdio`. Claude Code now spawns the process directly instead of connecting to a pre-running HTTP server.

## 2026-04-12 — Unblock Opus 1M context on Max 20x

### Problem

`/model opus[1m]` in Claude Code CLI returned "not available for your
account" despite an active Max 20x subscription that entitles Opus 1M
context. `/context` showed `46.5k/200k tokens` instead of the 1M window.

Per upstream issue [anthropics/claude-code#45449][issue], this is a
client-side gate bug compounded with a backend header bug:

1. **Backend bug**: Anthropic's API emits
   `anthropic-ratelimit-unified-overage-disabled-reason: org_level_disabled`
   on Max *personal* accounts with no org policy — a mis-scoping of
   personal plans into an org-disabled bucket.
2. **Client bug**: Claude Code's `/model opus[1m]` gate checks a
   locally cached copy of that header (`cachedExtraUsageDisabledReason`
   plus five related keys in `~/.claude.json`) instead of the live
   entitlement API. Once poisoned, the cache persists across
   `claude auth logout/login` and CLI restarts.

The actual request path is fine — submitting `claude-opus-4-6[1m]`
directly at request time succeeds at 1M context. Only the interactive
`/model` slash command is gated.

Verified on this machine: `~/.claude.json` contained
`cachedExtraUsageDisabledReason: "org_level_disabled"` and
`oauthAccount.hasExtraUsageEnabled: false`, matching the issue's
diagnosis exactly.

### Solution

Two-part fix, both managed by chezmoi:

**`dot_zshenv.tmpl`** — export `ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-6[1m]'`.
This bypasses the broken client-side gate entirely by making the CLI
submit `[1m]` directly at request time, regardless of what the cached
entitlement state says. This is the stable workaround confirmed by
multiple users in the upstream issue.

**`modify_dot_claude.json.tmpl`** — extended the existing modify script
to scrub the poisoned entitlement cache keys on every `chezmoi apply`,
alongside the existing MCP server management:

- `cachedExtraUsageDisabledReason`
- `hasAvailableSubscription`
- `s1mAccessCache`
- `passesEligibilityCache`
- `clientDataCache`
- `oauthAccount.hasExtraUsageEnabled`

The server will eventually re-poison `cachedExtraUsageDisabledReason`
from the stale header, but every `chezmoi apply` will wipe it again,
and the env var makes the 1M context work regardless.

Also ran the scrub once manually against the live `~/.claude.json` so
the fix takes effect immediately without waiting on the next apply.

### Verification

After sourcing the new env var and restarting Claude Code, `/context`
should report `x/1m tokens` instead of `x/200k tokens`.

### Future cleanup

When Anthropic ships a fix (expected to: have `logout` clear the cache
keys, give the caches a short TTL, and have the `/model` gate consult
the same entitlement API as the request path), the env var and the
scrub block can both be removed. Track the upstream issue for
resolution.

[issue]: https://github.com/anthropics/claude-code/issues/45449

## 2026-04-16 -- Add cortex MCP to user-level config for subagent inheritance

### Problem

Tatl subagents (dispatched via Claude Code's Agent tool) couldn't claim cortex tasks. The cortex MCP was only configured in Navi's project-level `.mcp.json` at `~/navi/.mcp.json`. Subagents appear not to inherit project-level MCP connections reliably, causing `cortex_claim` to fail with "Task claim storage is unavailable." This blocked all autonomous Continue ticks overnight (7 consecutive skips).

### Solution

Added cortex MCP server to the user-level modify script (`modify_dot_claude.json.tmpl`) with a `nimbus` hostname guard so it only deploys on the Mac Mini where the Expedition infrastructure runs. The cortex config includes DATABASE_URL, CORTEX_CONFIG, and CORTEX_DRIZZLE_PATH pointing to the local postgres (port 5433) and lumiere vendor paths.

Applied via `chezmoi apply ~/.claude.json`. Cortex is now available to all Claude Code sessions and subagents on nimbus, regardless of which project they spawn in.

Note: the `automation` MCP server (`http://localhost:3010/stream`) that was previously in `~/.claude.json` (likely added manually) was not in the chezmoi base definition and was removed by this apply. If needed, it should be added to the modify script's base.

## 2026-04-16 -- Add DATABASE_URL to zshenv for Tatl subagent inheritance

### Problem

Cortex MCP claim storage requires DATABASE_URL. The env var was set in Navi's `.mcp.json` and in the user-level `~/.claude.json` (via chezmoi modify script), which made claims work from the main session. However, Tatl subagents spawned via Claude Code's Agent tool start their own MCP server processes and do not reliably inherit the parent session's MCP env vars. Every autonomous Continue tick dispatched to a Tatl failed with "Task claim storage is unavailable" because the Tatl's cortex MCP instance had no DATABASE_URL.

### Solution

Added `DATABASE_URL` as a shell-level env var in `dot_zshenv.tmpl` with a nimbus hostname guard. This ensures all child processes (including Tatl subagent MCP servers) inherit the var from the shell environment, regardless of how they were spawned. Also edited the live `~/.zshenv` directly so the fix takes effect in the current session without requiring `chezmoi apply` (which needs 1Password).

## 2026-04-24 — Remove pty-mcp and obsidian, add Perplexity MCP

### Changes
- Removed `pty-mcp` from `modify_dot_claude.json.tmpl` (broken `oneOf` schema, already removed from Codex on 2026-04-21)
- Removed `obsidian` (`@bitbonsai/mcpvault`) from `modify_dot_claude.json.tmpl` (also removed from Codex config)
- Added `perplexity` (`@perplexity-ai/mcp-server`) MCP server — API key inherited from shell env
