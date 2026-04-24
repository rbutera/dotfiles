# Claude Code config changes log

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
