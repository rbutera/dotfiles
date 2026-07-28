# Claude Code config changes log

## 2026-07-28: shell-trap-check added as a second PreToolUse Bash hook

**Problem.** On the night of 2026-07-27/28 Navi hit five distinct instrument failures in one session: a truncated pretty-print produced a wrong count that reached Rai twice; a WebSearch summary produced a fabricated quote that reached him as fact and had to be retracted; a case-sensitive grep produced a false "that comment never landed"; a noise filter silently dropped a real member from an applicability sweep; and backticks inside a double-quoted shell string executed two bead ids as commands and deleted them from a memory file.

**Every one was already documented** in `~/expedition/Corrupt Instruments.md` or `~/expedition/Shell Quoting Traps On Nimbus.md`. Two were documented by Navi herself, hours earlier, the same night. That is the exact failure those documents describe, aimed at themselves: a correct thing living where nothing reads it at the moment of danger.

**Change.** `node /Users/rai/navi/bin/shell-trap-check.mjs` appended to the existing `Bash` matcher in `.hooks.PreToolUse`, alongside `rtk hook claude`. It reads the PreToolUse payload on stdin and warns on seven mechanically-detectable traps, each of which has cost something real: credential-leaking `${VAR:-x}` presence tests, `git add -A` in a shared tree, backticks inside double quotes, bare `>` under noclobber, establishing an absence from `head`/`tail` piped to grep, `bd list`/`bd ready` counted without `--limit 0`, and the Rule 76 destructive-git set.

⚠️ **It WARNS and never blocks, deliberately.** A blocking hook that false-positives gets switched off, and a switched-off guard is worse than none because it also carries the belief that something is watching. If a rule becomes noisy, delete the rule rather than the hook.

**Why the source and not the deployed file.** `.hooks.PreToolUse` is REBUILT wholesale by this modify script (line ~111), so an edit to `~/.claude/settings.json` alone would have been wiped on the next `chezmoi apply`. Caught by reading the script before trusting the edit. Verified after: `chezmoi diff ~/.claude/settings.json` shows only a trailing-newline difference, so source and live now agree.

**Tests.** `~/navi/tests/test_shell_trap_check.mjs`, 14 passing. The load-bearing one is the negative case: twelve ordinary everyday commands must produce zero warnings, because the false-positive rate is what decides whether this survives contact.

## 2026-07-24 — Manage `permissions.defaultMode` so SUBAGENTS stop blocking silently

### Context
A dispatched subagent doing a conflict-heavy git merge sat at zero progress for
about 35 minutes. From the orchestrator's side this was indistinguishable from
slow work: merge in progress, files staged, load normal, no error, no timeout,
no idle signal. It was actually **stuck on a bash permission prompt** with nobody
to answer it. Rai found it by running `ark attach`; approving the prompt
unblocked it immediately (0 → 5 conflicts resolved within a minute).

The cause: Rai runs his own session with the `--dangerously-skip-permissions`
CLI flag. **A CLI flag applies only to the session it launched.** A spawned
subagent starts as its own session, does not inherit the flag, and falls back to
the settings files. `defaultMode` was set in NONE of the three
(`~/.claude/settings.json`, `~/focused/.claude/settings.json`,
`.claude/settings.local.json`), so the only thing a subagent found was a
19-entry allow list in the project-local file. Any bash command outside those 19
prompted, and hung.

Ruled out along the way: the agent definition (`.claude/agents/rick.md`) has no
`tools:` or permission override, only name/description/model.

### Change (`dot_claude/modify_settings.json`)
- Added `"permissions": {"defaultMode": "bypassPermissions"}` to the managed base.
- jq now sets **`.permissions.defaultMode` only**, deliberately, so any
  `allow`/`deny` lists already in a deployed file survive untouched. The header
  comment was updated: `permissions.defaultMode` is now managed, the rest of
  `permissions` stays free.

### Why in settings rather than a flag
Settings are what a subagent actually inherits. Fixing it in the deployed file
by hand would have worked on this machine (the jq merge never touches
`.permissions`, so it survives `chezmoi apply`), but it would be untracked, and
a rebuilt machine would silently reacquire the bug with nobody remembering why.
Tracked and reproducible beats locally correct.

### Verification
- Dry-run: piped the real deployed settings through the script, confirmed
  `defaultMode` set and other managed keys intact. Calibrated the check by
  confirming it reports `NOT SET` against the pre-change file, so a zero result
  was demonstrably capable of being non-zero.
- Applied with a targeted `chezmoi apply ~/.claude/settings.json` (avoids the
  1Password prompt that a full apply triggers; no session was active).
- End-to-end: spawned a throwaway subagent and had it run a command
  deliberately absent from every allow list. Verdict: RAN WITHOUT PROMPT.

### Blast radius (deliberate, worth knowing)
This is global, so it applies to every machine and every agent identity,
including Navi on nimbus. Nothing changes for an interactive session Rai
launches with the flag; what changes is that **dispatched agents now get the
same latitude he already has**. Given they already write to client repos on his
behalf, that was judged the right posture. Reverting is a one-line removal.

## 2026-07-13 — Roll out mobile-mcp (android) + cua-driver (computer-use) everywhere

### Context
Next step after round-1 cleanup: pick the best Android + Computer-use MCP from
the vault surveys (`~/expedition/References/Android and Mobile MCP Servers…`,
`…Open-source Computer-use MCPs…`) and wire them into every harness.
- **Android winner: `mobile-next/mobile-mcp`** (`@mobilenext/mobile-mcp`) — 5.4k★,
  a11y-tree-first hybrid, full app lifecycle; npx (portable).
- **Computer-use winner: Cua `cua-driver`** (trycua/cua, ~19.5k★) — background,
  accessibility-grounded. It's a **PyPI package** (`cua-driver 0.7.1`), so invoked
  via `uvx cua-driver mcp` (no global binary — consistent with our other uvx MCPs,
  works identically on both machines, and fixes the previously-dead
  `command:"cua-driver"` entry that had no binary anywhere).

### Changes (`modify_dot_claude.json.tmpl`)
- Moved `mobile-mcp` + `cua-driver` **out of the nimbus-only block into the shared
  base** so kinto/Florence get them too.
- `cua-driver` command changed from bare `cua-driver` → `uvx cua-driver mcp`.
- `cortex` and `serena` stay nimbus-gated (Florence has her own serena).

### Runtime prerequisites (not config)
- `cua-driver` on macOS needs Accessibility + Screen-Recording grants once:
  `cua-driver permissions grant`.
- `mobile-mcp` needs `adb` (Android platform-tools) + a connected/emulated device
  to actually operate; the server itself starts fine without them.
- nimbus Codex also keeps ChatGPT-desktop's own `computer-use`/`node_repl` (app-
  managed) alongside `cua-driver` — both present by design.

### Verification
`chezmoi apply` on nimbus; live `~/.claude.json` cua-driver = `uvx cua-driver mcp`,
mobile-mcp present. Codex + OpenCode got both too (see logs/codex.md, logs/opencode.md).
Kinto synced via `chezmoi update`. Takes effect in new sessions.

## 2026-07-13 — MCP cleanup round 1 (Claude-side dedup + prune)

### Context
First round of a cross-harness MCP cleanup initiative (anchor:
`~/expedition/Installed Agent Harnesses/`). This round does only the
unambiguous Claude-side removals/dedup; android/computer-use rollout is a
separate later step.

### Changes
- **Removed `open-websearch`** from `modify_dot_claude.json.tmpl` base mcpServers
  (all machines) — redundant with `exa`.
- **Deduped `context7`**: Claude was loading it *twice per session* — the managed
  global stdio (`npx @upstash/context7-mcp`) **and** the
  `context7@claude-plugins-official` plugin (also npx, identical mechanism). Kept
  the managed global stdio; added `context7` to the `del()` list in
  `dot_claude/modify_settings.json` so the plugin is stripped on apply.
- **Removed `chrome-devtools-mcp@claude-plugins-official`** plugin (dropped from
  base + added to the `del()` list) — browser control is covered by `playwright`.
- **Enabled serena for nimbus Navi**: added a **nimbus-gated** `serena` entry to
  `modify_dot_claude.json.tmpl` mcpServers — `uvx --from
  git+https://github.com/oraios/serena serena start-mcp-server --context
  claude-code`, mirroring Florence's kinto `~/focused/.mcp.json` entry. Done via
  mcpServers (not the plugin, kept deliberately off) so kinto/Florence — which
  already has serena in its own `.mcp.json` — doesn't double-load. Verified the 7
  serena tools referenced in `~/.claude/rules/serena.md`
  (`get_symbols_overview`, `find_symbol`, `find_referencing_symbols`,
  `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`,
  `rename_symbol`) are all current, real serena tools.

### Deferred to the next step (not this round)
`mobile-mcp` (android) + `cua-driver` (computer-use) "available everywhere incl.
Codex". `cua-driver` has **no binary on either nimbus or kinto** — so it's
currently a dead entry even on nimbus. Rolling it out belongs to the vault-driven
"select best android + computer-use MCP, then install" step, which will install
the binary first.

### Verification
`chezmoi apply --force ~/.claude.json ~/.claude/settings.json` on nimbus (EXA_API_KEY
confirmed in env first — the modify script injects it, empty would blank the exa
key). Live `~/.claude.json` mcpServers now include `serena`, no `open-websearch`;
`enabledPlugins` has no `context7`/`chrome-devtools-mcp`; exa key intact. Kinto
brought in sync via `chezmoi update`. serena takes effect in new Claude sessions.

## 2026-07-13 — Disable the `Claude-Session:` commit trailer (`attribution.sessionUrl: false`)

### Context
Claude Code appends a `Claude-Session: https://claude.ai/code/session_...` git
trailer to commit messages by default when running from a web or Remote Control
session. This is AI attribution, and it leaked into a commit in an easyJet-owned
client repo (`~/focused/launchpad/`), where Rai must be the sole attributed
author. It had to be caught and stripped by hand — a Brita-filter violation:
anything that depends on a human remembering will eventually fail.

`attribution.commit: ""` (already set) only suppresses the `Co-Authored-By:`
trailer. The session link is a separate flag. Per the docs
(https://code.claude.com/docs/en/settings#attribution-settings): "`sessionUrl` —
Whether to append the claude.ai session link as a `Claude-Session` trailer on
commits and a link in pull request descriptions when running from a web or
Remote Control session. Defaults to `true`. Set to `false` to omit the link." The
same section notes `attribution` supersedes the deprecated `includeCoAuthoredBy`
key, and that hiding all attribution needs `commit` + `pr` empty **and**
`sessionUrl: false`.

### Changes
- **`dot_claude/modify_settings.json`**: base config `attribution` block now
  `{"commit": "", "pr": "", "sessionUrl": false}`. `attribution` is a
  fully-managed key in the jq merge, so this deploys to every machine.

### Verification
`chezmoi apply ~/.claude/settings.json` (scoped, no 1Password needed — this
source file is not a template). Deployed `~/.claude/settings.json` now has
`.attribution == {"commit": "", "pr": "", "sessionUrl": false}` and is valid JSON.

## 2026-06-24 — Remove all `.claude.json` cache scrubs (supersedes 2026-06-22)

### Context
During a `/chezmoi-sync` reconciliation, `.claude.json` again showed `MM` drift.
Per Rai's call, the 1M-context entitlement cache poisoning (#45449) "is no
longer a thing" — so the `modify_dot_claude.json.tmpl` scrub block is now
obsolete. This **overrides the 2026-06-22 finding** below, which had concluded
the scrub was still needed because the machine kept getting re-poisoned. Rai is
deliberately overriding that verification.

### Changes
- **`modify_dot_claude.json.tmpl`**: Removed the entire cache-scrub `del()`
  chain from the jq transform — `cachedExtraUsageDisabledReason`,
  `hasAvailableSubscription`, `s1mAccessCache`, `passesEligibilityCache`,
  `clientDataCache`, and `oauthAccount.hasExtraUsageEnabled`. Also removed the
  now-stale explanatory comment block referencing #45449. The script now only
  manages `mcpServers`, built-in `enabledMcpServers`, and `remoteControlAtStartup`.
- Applied `chezmoi apply --force ~/.claude.json`. Deployed file keeps all its
  runtime fields untouched; the only residual diff is a trailing-newline (jq
  emits one, Claude Code writes none) — cosmetic and harmless.

### Side effect — less drift
Removing the scrub also reduces `.claude.json`'s perpetual churn: the script no
longer deletes the runtime keys Claude Code re-writes, so the modify output and
the live file now agree on those keys. The 1M model is still pinned separately
via `ANTHROPIC_DEFAULT_OPUS_MODEL` in `dot_zshenv.tmpl` (left in place).

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

## 2026-07-17 — Remove personal-host CLAUDE_CODE_OAUTH_TOKEN export from claude-ai.zsh

### Problem

Every `chezmoi apply` re-injected `CLAUDE_CODE_OAUTH_TOKEN` into the shell environment via the else-branch in `dot_config/zsh/claude-ai.zsh.tmpl` (personal hosts, `op://Private/claude code token/credential`). An ambient env token takes precedence over keychain/`claude auth login` credentials, flipping the CLI to API-key billing — the same conflict documented in the 2026-era removal that was later reverted. Rai has moved off this token entirely.

### Verification

- Empirical: `env -u CLAUDE_CODE_OAUTH_TOKEN -u ANTHROPIC_API_KEY claude -p 'reply ok' --model haiku` succeeds via keychain on nimbus — headless mode needs no token env var.
- Docs (code.claude.com/docs/en/authentication): `CLAUDE_CODE_OAUTH_TOKEN` is step 5 in the credential precedence chain; subscription OAuth from `/login` (macOS Keychain) is the default step 6 and works in `--print` mode. The token is only *required* for `--bare` mode or environments with no keychain/login (CI).

### Changes

- **`dot_config/zsh/claude-ai.zsh.tmpl`**: Removed the personal-host `export CLAUDE_CODE_OAUTH_TOKEN=…` else-branch; work hosts keep `CLAUDE_CODE_OAUTH_TOKEN_WORK`. Added a comment explaining why.
- **Deployed `~/.config/zsh/claude-ai.zsh`**: Edited directly to match the new render (1Password signin failed in-session, so `chezmoi apply` couldn't render the template). No functional diff vs source.
- Kept the `unset CLAUDE_CODE_OAUTH_TOKEN` alias in `dot_aliases.tmpl` (per Rai) — harmless, and still useful in shells with a stale env.

### Not touched (separate consumers with their own token copies)

- `dot_config/impulse/dot_env.tmpl` (ark-spawn jobs) and the PowerShell profile still template the token.
- `~/Library/LaunchAgents/com.lumiere.discord-text-plugin.plist` hardcodes a literal token (not chezmoi-managed); lumiere `apps/ark/.env` and `infra/cortex-lab/**/.env` hold three more distinct literal tokens. These should be revoked/migrated to keychain auth as a follow-up.
