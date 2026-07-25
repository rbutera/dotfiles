## 2026-07-25 — GitHub MCP server was on the wrong token

`mcp_servers.github.bearer_token_env_var` in `dot_codex/modify_private_config.toml` was
`GITHUB_LLM_PAT`, a fine-grained PAT with no access to `easyjet-dev`, so every GitHub MCP
call against a client repo returned a bare 404. Changed to `GITHUB_TOKEN`, which carries
the SAML SSO grant. Full write-up, including the parallel `gh` fix, in `logs/shell.md`.

## 2026-07-22 — Revert the Claude→Codex leg to the bridge fork, with the fork's real defects fixed

### Why revert
The official plugin (`@openai/codex-plugin-cc`) hardcodes the Codex sandbox in two
places, neither configurable:

- `task --write` → `workspace-write`. A git worktree's `.git` is a *file* pointing at
  `<main-repo>/.git/worktrees/<name>`, outside the workspace, so Codex cannot commit.
  Worse, MSBuild workers and ASP.NET `WebApplicationFactory` test hosts misbehave under
  it, so Codex **silently excludes the tests it cannot run and reports green on the
  remainder**. On FUS-192 wave 1 it self-reported "1,020 passed"; the real unfiltered
  suite was 23 failed / 1161 passed / 1188 total, all 23 in the excluded hosted tests.
- `review` / `adversarial-review` → `read-only`. The reviewer cannot build or test to
  verify its own claims, and stalled for 7 and 21 minutes trying.

### What was NOT true in the 2026-07-19 entry below
That entry claims the fork's hardcoded `/Users/rai/...` path was "broken on kinto/nimbus
(Linux, `/home/rai`)". **All three machines are macOS with `/Users/rai`** (verified
2026-07-22 on kinto, nimbus and latios). The portability half of the migration rationale
never applied. The path is now templated as `{{ .chezmoi.homeDir }}` anyway, so the
concern is moot rather than merely wrong.

### The saturation concern was real, and is now fixed at source
Reverting alone would have re-adopted the defect the migration was for, so the fork was
fixed first (`rbutera/claude-codex-bridge`, commit `c90a698`):

1. **Shared thread pointer.** A module-global `lastThreadId` was read/written by every
   concurrent call in the single MCP process, so parallel reviewers stomped each other.
   Continuity is now an explicit opt-in `threadKey`; without one, every call gets its own
   thread. This is the actual "saturation" root cause.
2. **Silent sandbox downgrade.** `codex exec resume` accepts no `--sandbox` flag. The old
   code resumed whenever the global was set, so `danger-full-access` silently inherited
   the resumed thread's sandbox — only the *first* call per process lifetime ever honoured
   its argument. A thread is now resumed only when its recorded sandbox matches.
3. **Read-only reviewers.** The four analysis tools hardcoded `sandbox: "read-only"` —
   the *same* defect as the plugin's review path. Sandbox is now a parameter on all four,
   still defaulting to read-only.

Plus a FIFO-fair bounded semaphore (`CODEX_BRIDGE_MAX_CONCURRENT`, default 4) so N
reviewers cannot spawn N unmanaged subprocesses. Every new test was mutation-checked.

### Changes (chezmoi source)
- **`modify_dot_claude.json.tmpl`**: `codex` MCP server restored, path templated with
  `{{ .chezmoi.homeDir }}` instead of the old hardcoded absolute path.
- **`dot_claude/modify_settings.json`**: `codex@openai-codex` removed from managed base
  **and added to the `del(...)` list** — base-removal alone is not enough, since
  `enabledPlugins` merges with `*` and would preserve the deployed `true`. Likewise the
  `extraKnownMarketplaces` merge is replaced by an explicit
  `del(.extraKnownMarketplaces["openai-codex"])`, since that merge was purely additive.
  The **`orcaHook` fold is deliberately KEPT** — it was an unrelated real fix that merely
  rode along in the same migration commit.
- **Restored**: `dot_claude/skills/codex/` and `dot_claude/agents/codex-teammate.md`,
  recovered from `c823e3f^` rather than retyped.
- **Deleted `.chezmoiremove`**: it existed solely to retire those two targets. Leaving it
  would have silently re-deleted them on every apply.
- **`dot_claude/skills/wave/SKILL.md`**: step 4c back to the `codex-teammate` agent, and
  the implementer block back to `mcp__codex__codex_implement` with the worktree
  `danger-full-access` rule. Documents the new `sandbox` and `threadKey` arguments.
  The **test-count rule is kept** — it is the durable lesson, independent of which bridge wins.

### Kept
Reverse leg (Codex→Claude) unchanged: `[mcp_servers.claude]` = `claude-codex-bridge@0.3.1`
via npx. Note this is the **npm package, not the fork**, so it does not carry the fork's fixes.

# Codex config changes log

## 2026-07-19 — Migrate Claude→Codex leg from the bridge fork to the official OpenAI Codex plugin

### Context
The community `claude-codex-bridge` fork (deployed as the `codex` MCP server) was
reported "saturated" under concurrent review load. Root cause: a single MCP process
with one module-global `lastThreadId` that every concurrent tool call stomps (see
vault `References/Codex Bridge`). Separately, the fork's `codex` MCP entry was
hardcoded to `/Users/rai/dev/claude-codex-bridge/dist/cli.mjs` in the **shared**
base block — a macOS path, so it was **broken on kinto/nimbus** (Linux `/home/rai`).

Replacement: OpenAI's official plugin **`@openai/codex-plugin-cc`** (marketplace
`openai-codex`, repo `openai/codex-plugin-cc`). Its runtime uses a per-repo Codex
app-server broker with an automatic dedicated-server fallback on BUSY
(`scripts/lib/codex.mjs`), so concurrent reviews don't collide — fixes saturation.
Portable (npx/plugin, no absolute path). Full rollout plan + rationale:
vault `References/Codex Bridge Migration`.

### Changes (chezmoi source)
- **`modify_dot_claude.json.tmpl`**: removed the `codex` MCP server block (the
  Claude→Codex bridge leg). base is authoritative, so apply drops it from
  `~/.claude.json`.
- **`dot_claude/modify_settings.json`**: added `"codex@openai-codex": true` to the
  managed base `enabledPlugins`, and added a managed (additive) `extraKnownMarketplaces`
  merge registering the `openai-codex` marketplace so all machines auto-clone it on
  launch (previously only latios knew it — `extraKnownMarketplaces` was unmanaged).
- **`dot_claude/skills/wave/SKILL.md`**: rewired review-gate step 4c — Agent 2 (Codex)
  now dispatches a `general-purpose` agent that runs
  `node "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs" review --base <base> --scope branch --wait`
  and returns Codex's output verbatim, instead of the `codex-teammate` agent +
  `mcp__codex__*` tools. `disable-model-invocation` on `/codex:review` only gates the
  slash command, not this node runtime path — so no plugin fork was needed.
- **Retired** (source deleted + added to new `.chezmoiremove` so apply removes the
  deployed targets fleet-wide): `dot_claude/skills/codex/` and
  `dot_claude/agents/codex-teammate.md` — both depended on the now-removed `codex`
  MCP tools.

### Kept (deliberately)
- **Reverse leg unchanged**: `dot_codex/modify_private_config.toml`
  `[mcp_servers.claude]` = `claude-codex-bridge@0.3.1 serve claude` stays. The plugin
  is Claude→Codex only; the bridge still provides Codex→Claude.

### Verification
- Rendered both modify scripts via `chezmoi cat`: `~/.claude.json` valid JSON, `codex`
  MCP server gone, 8 servers remain; `settings.json` valid, `codex@openai-codex`
  enabled, `openai-codex` marketplace known, 14 other plugins preserved.
- Per-machine `chezmoi apply` + `/reload-plugins` + `/codex:setup` done during rollout
  (kinto first, then nimbus/latios). Focused-repo review skills (`/reviewed-implementation`,
  `/cleanup-review`) rewired separately in the `focused` repo (not chezmoi-managed).

Installed the official native CUA Driver app and replaced the cache-backed
`uvx cua-driver mcp` registration with the canonical absolute command emitted by
`cua-driver mcp-config --client codex`: `/Users/rai/.local/bin/cua-driver mcp`.
This gives app-launched Codex sessions a stable path and makes macOS Accessibility
and Screen Recording grants attach to the signed `com.trycua.driver` bundle.

## 2026-07-14 — Remove chisel MCP server

Rai retired `chisel`. Removed `chisel` from `BASE["mcp_servers"]` in
`dot_codex/modify_private_config.toml` and dropped it from the Windows `pop()`
list (now `("tempograph", "oss-autopilot")`). Applied `chezmoi apply --force
~/.codex/config.toml` (python modify script, no 1Password) — live config now
chisel-free, diff empty. Also removed from the claude modify script the same day;
see logs/chezmoi-modify-scripts.md (pi inherits MCP via discovery, no pi-native
config to edit).

## 2026-07-13 — Fix `HOME` NameError in the kinto Florence codex section

Bug (pre-existing, kinto-only): the Florence `obsidian` entry used a bare,
undefined `HOME` — `os.path.join(HOME, "focused", "vault")` — so the whole modify
script raised `NameError` and **every kinto `chezmoi apply ~/.codex/config.toml`
was failing** (surfaced while rolling out mobile-mcp/cua-driver). Fixed to
`os.path.expanduser("~")` → `/Users/rai/focused/vault` (verified against Florence's
live `~/focused/.mcp.json`). nimbus never hit it (kinto-gated branch).

## 2026-07-13 — Add mobile-mcp (android) + cua-driver (computer-use) to Codex

### Change
Added two MCP servers to `BASE["mcp_servers"]` in
`dot_codex/modify_private_config.toml` (shared base — both machines), part of the
cross-harness android/computer-use rollout (see logs/claude.md same date for the
survey rationale and the full picture):
- `mobile-mcp` → `npx -y @mobilenext/mobile-mcp@latest` (android device control;
  needs adb + a device to operate).
- `cua-driver` → `uvx cua-driver mcp` (trycua/cua computer-use; macOS needs
  `cua-driver permissions grant` once).

Note: nimbus Codex still carries ChatGPT-desktop's own `node_repl` + `computer-use`
(app-managed, preserved by the merge logic) alongside `cua-driver` — both by design.

### Verification
`chezmoi apply ~/.codex/config.toml` on nimbus (python modify script, no 1Password);
both `[mcp_servers.mobile-mcp]` and `[mcp_servers.cua-driver]` present, exa key intact.
Kinto synced via `chezmoi update`.

## 2026-07-13 — Set approval_policy back to `never` (full auto-approval)

### Problem
Rai asked Codex to stop prompting for approval and just auto-grant it. Codex CLI
0.144.1 uses the permission-profile scheme; per the official docs
(https://learn.chatgpt.com/docs/config-file/config-reference), fully autonomous
no-prompt operation is exactly `approval_policy = "never"` +
`default_permissions = ":danger-full-access"`. The base already had
`:danger-full-access`, so the only key still forcing prompts was
`approval_policy = "on-request"`.

### Changes
- **`dot_codex/modify_private_config.toml`**: `BASE["approval_policy"]` changed
  from `"on-request"` back to `"never"`.

### Note — this reverses the entry directly below (same day)
Earlier today `never` was switched to `on-request` because, paired with the
*legacy `[sandbox]`* config, `never` left Codex unable to escalate past a
sandbox block. That reasoning no longer applies: the same earlier change also
removed the legacy sandbox and set `default_permissions = ":danger-full-access"`
(unrestricted local access), so there is nothing left to block/escalate. With
full access already granted, `never` is the intended "no safety net, fully
autonomous" mode — which is what Rai explicitly requested.

### Verification
`chezmoi apply ~/.codex/config.toml` (scoped; this source is a `modify_` python
script, not a template — no 1Password needed). Deployed `~/.codex/config.toml`
now shows `approval_policy = "never"` and `default_permissions = ":danger-full-access"`.

## 2026-07-13 — Remove sandbox friction and allow escalation

### Problem
Codex desktop sessions were restricted to workspace writes and blocked outbound SSH to Tailscale hosts. `approval_policy = "never"` prevented Codex from requesting an escalation, while the legacy `[sandbox]` configuration did not provide the intended unrestricted local access.

### Changes
- Changed the managed approval policy from `never` to `on-request` so Codex can request confirmation when a separate safety rule requires it.
- Set `default_permissions = ":danger-full-access"` for unrestricted local filesystem and network execution on Rai's personal machines.
- Removed the legacy `sandbox` settings from the managed base and explicitly delete stale `sandbox`, `sandbox_mode`, and `sandbox_workspace_write` keys while merging an existing deployed config, preventing old sandbox policy from overriding the permission profile.
- Preserved desktop-app-owned `node_repl`, computer-use, bundled, and primary-runtime integration entries during authoritative merges; added Slack to the managed curated plugin set. This prevents a targeted Codex config apply from deleting working integrations discovered in the live config.

## 2026-07-11 — Use high reasoning effort for GPT-5.6 SOL

Changed the managed Codex default `model_reasoning_effort` from `medium` to
`high`. The default model remains `gpt-5.6-sol`.

## 2026-07-07 — Convert codex-teammate into a faithful Sonnet-low relay

### Problem
The `codex-teammate` agent and the `/wave` Codex reviewer were defined so that a host Opus agent would gather context, read files, call Codex, then rewrite Codex's answer ("synthesize, don't parrot"). This defeated both reasons to use Codex: it contaminated Codex's **independent** second-model read (Opus framed the input and editorialized the output), and it burned Anthropic tokens doing work Codex should do itself. The "Opus does the work then relays" behavior lived entirely in these markdown files, not in the `claude-codex-bridge` MCP server (which already passes prompts to `codex exec` verbatim).

### Changes
- `dot_claude/agents/codex-teammate.md` — rewrote into a deliberately cheap, faithful **relay**:
  - Frontmatter pinned to `model: sonnet` + `effort: low`, and a `tools:` allowlist restricted to only the six `mcp__codex__codex_*` tools so it *structurally* cannot read files.
  - Body inverted: no file reading, no context gathering, no opinion forming, no synthesis. It routes to the right Codex tool, always passes `workingDirectory` (Codex reads the repo itself), forwards the caller's task verbatim (self-contained, since Codex can't see chat history), and returns Codex's output under a fixed `— Codex —` header with nothing added.
- `dot_claude/skills/codex/SKILL.md` — left as the **synthesized, human-readable** `/codex` path (intended); added one line distinguishing it from the relay agent.
- `dot_claude/skills/wave/SKILL.md` — wired the "Agent 2 (Codex)" review-gate reviewer to dispatch via the `codex-teammate` agent with **no spawn-time `model` override** (a spawn-time model beats frontmatter and would force Opus, re-breaking independence). Scoped its inputs to the review target + caller-known paths, not Agent 1's "read the diff" instructions; narrowed the inline fallback to genuine agent-unavailability.

### Process
Implemented by a Sonnet subagent, then dual-reviewed by Codex + Opus in parallel. Codex initially FAILed (missing `tools:` allowlist; `context` param invited background-gathering; `/wave` "same inputs as Agent 1" re-imported read instructions). Applied all findings, re-reviewed, Codex PASSed. Deployed via `chezmoi apply` (plain `.md` files — no 1Password session needed). Takes effect in new Claude Code sessions.

## 2026-03-28 — Fix macOS editor path and template Codex home paths

### Problem
Codex CLI could not open `nvim` on macOS because the shell config exported `EDITOR` as a Linux-only path: `/home/rai/.local/share/bob/nvim-bin/nvim`.

### Changes
- Updated `dot_zprofile.tmpl` and `dot_zshrc.tmpl` to export an absolute Neovim path derived from the user's home directory instead of a Linux-specific `/home/rai/...` path.
- Replaced hardcoded `/home/rai` paths in `dot_zshrc.tmpl` with `$HOME` for:
  - OpenClaw completions
  - OpenCode bin path
  - pnpm path check on macOS
- Converted `dot_codex/private_config.toml` into `dot_codex/private_config.toml.tmpl`.
- Replaced hardcoded home-directory paths in the Codex config with `{{ .chezmoi.homeDir }}` so sandbox roots and trusted project paths render correctly on both macOS and Linux.
## 2026-03-28 — Sync Codex template with live config

### Problem
The chezmoi Codex config template had drifted from the live `~/.codex/config.toml`. Useful changes in the live file were not reflected in the managed template.

### Changes
- Updated the template default model from `gpt-5.3-codex` to `gpt-5.4`.
- Updated `model_reasoning_effort` from `high` to `medium`.
- Added plugin enablement blocks for:
  - Google Calendar
  - Gmail
  - GitHub
  - Google Drive
- Kept home-directory paths templated with `{{ .chezmoi.homeDir }}` instead of copying hardcoded `/home/rai` entries from the live file.
- Dropped the stray mac-only duplicate project entry because the templated chezmoi project path already covers it.

## 2026-03-28 — Add macOS Homebrew path and Colima Docker socket

### Problem
macOS shell startup needed explicit Homebrew bin precedence and a Colima-backed Docker socket for local Docker clients.

### Changes
- Updated `dot_zprofile.tmpl` to add `export PATH=/opt/homebrew/bin:$PATH` on macOS.
- Updated `dot_zprofile.tmpl` to add `export DOCKER_HOST=unix://$HOME/.colima/default/docker.sock` on macOS.

## 2026-04-08 — Fix MCP startup failures in Codex CLI

### Problem
Six MCP servers were failing on startup: `chisel` and `pty-mcp` (missing binaries), `Sanity` (missing env var), `mcp-alchemy` (missing `DB_URL`), `better-notion-mcp` (missing `NOTION_TOKEN`), `tempograph` (missing repo arg).

### Changes
- Installed `chisel` MCP server from `ckanthony/Chisel` GitHub repo via `cargo install --git`.
- Installed `pty-mcp` v0.3.0 from crates.io via `cargo install`.
- Reshimmed asdf so both binaries are on PATH.
- Removed `mcp-alchemy` from `dot_codex/modify_private_config.toml` (no database to connect to).
- Applied updated config via `chezmoi apply ~/.codex/config.toml`.
- Fixed `tempograph`: changed entrypoint from `tempograph` (CLI, requires `repo` arg) to `tempograph-server` (MCP stdio server). The package exposes three entrypoints: `tempograph` (CLI), `tempograph-server` (MCP), and `tempo` (alias).
- Remaining unfixed: `Sanity` (needs `SANITY_MCP_TOKEN`), `better-notion-mcp` (needs `NOTION_TOKEN`).

## 2026-04-11 — Remove open-websearch MCP server

### Problem
Rai requested global removal of the `open-websearch` MCP server from Codex CLI.

### Solution/Fix
- Removed the `open-websearch` entry from the `mcp_servers` dict in `dot_codex/modify_private_config.toml`.
- Applied via `chezmoi apply ~/.codex/config.toml`. No 1Password session needed (no secrets in this file).

## 2026-04-11 — Remove Sanity and better-notion-mcp MCP servers

### Problem
Rai requested global removal of `Sanity` and `better-notion-mcp` MCP servers. Neither had working credentials configured (Sanity needed `SANITY_MCP_TOKEN`, better-notion-mcp needed `NOTION_TOKEN`).

### Solution/Fix
- Removed `Sanity` and `better-notion-mcp` entries from `dot_codex/modify_private_config.toml`.
- Removed `better-notion-mcp` from `modify_dot_claude.json.tmpl` (Sanity was not present there).
- Applied both via `chezmoi apply`.

## 2026-04-21 — Remove pty-mcp MCP server

### Problem
pty-mcp's `ssh_connect` tool registers a schema with `oneOf`/`anyOf` at the top level, which violates the OpenAI tools API spec. This blocks ALL Codex threads from starting, making the Codex plugin unusable. The server was a fork that Rai installed but is not maintained.

### Changes
- Removed `pty-mcp` entry from `mcp_servers` in `dot_codex/modify_private_config.toml`
- Uninstalled `pty-mcp` cargo binary (`cargo uninstall pty-mcp`)
- Reshimmed asdf rust to clean up the stale shim

## 2026-04-24 — Remove obsidian, add Perplexity MCP, bump model to gpt-5.5

### Changes
- Removed `obsidian` (`@bitbonsai/mcpvault`) from `dot_codex/modify_private_config.toml`
- Added `perplexity` (`@perplexity-ai/mcp-server`) MCP server — API key inherited from shell env
- Bumped default model from `gpt-5.4` to `gpt-5.5`
- Changed `model_reasoning_effort` from `medium` to `high`

## 2026-04-26 — Add codex wrapper alias, caveman plugin, fix perplexity MCP

### Changes

- **`dot_aliases.tmpl`**: Added `codex()` shell wrapper that auto-injects `--dangerously-bypass-approvals-and-sandbox` (mirrors the existing `claude()` wrapper pattern). The `yolocodex` alias remains as a shorter alternative.
- **`dot_codex/modify_private_config.toml`**: Added `caveman@caveman-repo` plugin and `caveman-repo` marketplace source (git from `JuliusBrussee/caveman`).
- **`dot_codex/modify_private_config.toml`**: Fixed Perplexity MCP server startup — changed from bare `npx -y @perplexity-ai/mcp-server` to `zsh -c "exec npx -yq @perplexity-ai/mcp-server"` to ensure clean process lifecycle.

## 2026-05-15 — Add global AGENTS.md custom instructions

### Problem
GPT 5.x models in the Codex desktop app exhibit frustrating default behaviors: stopping mid-task and asking "would you like me to continue?", excessive bullet-point formatting, verbose filler phrases, false completion claims, and silent scope expansion. These are well-documented across Reddit, Hacker News, and Codex GitHub issues (#14414, #13799, #14341, #13950).

### Changes
- Created `dot_codex/AGENTS.md` — a global custom instructions file that Codex loads at session start.
- Covers six behavioral areas: autonomy/persistence, communication style (anti-verbosity, prose over bullets), code generation (complete implementations, no placeholders), planning/reasoning, formatting rules, honesty/accuracy, and scope discipline.
- Uses XML tag patterns (`<persistence>`, `<output_style>`, etc.) recommended by OpenAI's own GPT-5 prompting guide for strong instruction adherence.
- Deployed to both Linux (`~/.codex/AGENTS.md`) and Windows (`C:\Users\Rai\.codex\AGENTS.md`).

## 2026-04-24 -- Reasoning effort lowered to "low"

### Problem
Codex (Tael) calls were taking 5-10 minutes each, and one timed out entirely. Config had `model_reasoning_effort = "high"` which causes GPT-5.5 to overthink code tasks it's already strong at.

### Solution/Fix
Changed `model_reasoning_effort` from `"high"` to `"low"` in `dot_codex/modify_private_config.toml` BASE dict. Applied via `chezmoi apply`. Should significantly reduce Tael dispatch latency.

## 2026-07-10 — Revert codex-teammate to vanilla (Sonnet-low relay was a no-op)

### Problem
The 2026-07-07 "faithful Sonnet-low relay" (`model: sonnet`, `effort: low`, tools pinned to the six `mcp__codex__codex_*` only) did not route in practice: dispatched as the Codex reviewer for PR #571 it returned with `tool_uses: 0`, produced no findings, and just echoed its system preamble (~66k tokens spent, zero Codex calls). A review gate that silently yields nothing is worse than a slightly less "independent" but functioning one.

### Change
- `dot_claude/agents/codex-teammate.md` — reverted to the vanilla `c51f71d` definition (the one shipped with the bridge): no `model`/`effort`/`tools` frontmatter (inherits the caller's model + full tools), body reads context, calls the right Codex tool, and synthesizes. Applied via `chezmoi apply`.

### Trade-off accepted
Loses the strict "uncontaminated independent read" the relay aimed for; regains an actually-working Codex second opinion. Rai's call. Agent-definition changes take effect in new Claude Code sessions.
