# opencode config changes log

## 2026-06-19 — opencode broke after self-update; switch install method to standalone binary

### Problem
opencode's in-app self-updater bumped 1.15.10 → 1.17.8, after which **both**
`opencode` and `openagent` died with:
`Error: opencode-ai's postinstall script was not run.`
The pnpm global package dir (`~/Library/pnpm/global/5/node_modules/.pnpm/opencode-ai@1.17.8/...`)
was **empty** — no binary, no `postinstall.mjs`.

### Root cause
The global `~/.npmrc`/pnpm config (see `logs/npm.md`, 2026-05-23) sets
**`ignore-scripts=true`** plus `min-release-age=7` / `minimum-release-age=10080`.
opencode-ai is a *thin npm wrapper whose `postinstall` downloads the real
platform binary* — `ignore-scripts=true` blocks that step, so every npm/pnpm
install of opencode is left binary-less. The self-update made it worse (empty dir).
This is the same class as the node-24 global-CLI orphan runbook, but caused by
the install-scripts block rather than a node bump.

### Fix (durable — use this method going forward)
opencode should NOT be installed via npm/pnpm on this machine. Use the official
standalone installer, which drops a prebuilt binary into `~/.opencode/bin`
(already first in PATH via `dot_zshenv.tmpl` line 27) and needs no lifecycle scripts:
```bash
curl -fsSL https://opencode.ai/install | bash   # installs ~/.opencode/bin/opencode
pnpm rm -g opencode-ai                           # remove the broken/shadowing pnpm copy
hash -r; which opencode                          # -> /Users/rai/.opencode/bin/opencode
opencode --version                               # -> 1.17.8
```
The standalone binary's own self-updater works in-place (no npm), so future
updates won't re-trigger this. Verified after fix: vanilla `opencode agent list`
shows `build (primary)`, and `opencode run -m opencode-go/glm-5.2` returns `pong`.

## 2026-06-19 — Rip out oh-my-opencode-slim; two-profile system (vanilla `opencode` + `openagent`)

### Motivation
`oh-my-opencode-slim` (a community fork layered on opencode) was deemed
low-value ("dogwater"). Goal: strip it back to a vanilla-like opencode (MCP
servers + providers, no framework), then stand up a **side-by-side toggle** so
`opencode` is the clean vanilla profile and `openagent` is a clean swap-in with
the full `oh-my-openagent` framework on top — sharing one base config.

### Design
Mechanism: opencode's `OPENCODE_CONFIG_DIR` env var selects an entire config
directory. Two profiles, one shared base:

- `~/.config/opencode/`            → `opencode`  (vanilla: providers + MCP, no plugin, default agents enabled)
- `~/.config/opencode-openagent/`  → `openagent` (same shared base + `plugin: ["oh-my-openagent"]`)
- `~/bin/openagent` wrapper sets `OPENCODE_CONFIG_DIR=~/.config/opencode-openagent` and `exec opencode "$@"`.

Shared config is DRY: `.chezmoitemplates/opencode-shared-base` holds the common
`provider` (zai-anthropic) + `mcp` (camofox, exa, context7) + `skills` + `lsp`,
and is pulled into **both** profiles' `modify_*.json.tmpl` via `includeTemplate`.

### Changes (chezmoi source)
- **Deleted** `dot_config/opencode/modify_oh-my-opencode-slim.json` (slim plugin config).
- **Replaced** `dot_config/opencode/modify_opencode.json` → `modify_opencode.json.tmpl`:
  vanilla base via shared template; jq merge now actively strips `.plugin` and
  `.agent` so the slim registration + the `explore/general/build/plan` disable
  block are removed (default agents re-enabled).
- **Added** `.chezmoitemplates/opencode-shared-base` — shared provider/mcp/skills/lsp.
  Added `exa` (remote, `{env:EXA_API_KEY}`) and `context7` (remote) MCPs alongside camofox.
- **Added** `dot_config/opencode-openagent/modify_opencode.json.tmpl` — shared base + omo plugin overlay.
- **Added** `bin/executable_openagent` — wrapper (also sets `OMO_DISABLE_POSTHOG=1`, `OMO_SEND_ANONYMOUS_TELEMETRY=0`).

### Live cleanup (machine: latios)
- `chezmoi apply ~/.config/opencode/opencode.json` — live config now has no plugin,
  3 MCPs, default agents enabled. Verified `opencode agent list` shows `build (primary)`.
- Removed slim installer artifacts: skills `clonedeps`/`codemap`/`deepwork`/`simplify`,
  `oh-my-opencode-slim.json`, `opencode.json.bak`, `tui.json.bak`; cleaned `tui.json`
  (was registering slim plugin) to `{}`.
- **Kept**: `plugins/rtk.ts` (RTK token-killer, auto-loaded), its `node_modules`,
  and chezmoi-managed skills `become-navi` + `openspec-*`, theme `catppuccin-mocha-blue`.

### oh-my-openagent install — the two gotchas (both solved)

omo (`oh-my-openagent@4.11.1`) is installed into the **profile** node_modules and
loaded by opencode. Two environment-specific blockers had to be solved:

1. **Hardened npm env blocks the install.** Global `~/.npmrc` (`ignore-scripts`,
   `min-release-age=7`, `engine-strict`) prevents installing opencode's plugin SDK
   and omo (a bun-built source package whose `dist/` is produced by a postinstall).
   Fix: a **scoped `~/.config/opencode-openagent/.npmrc`** (chezmoi: `dot_npmrc`)
   lifting those gates for this dir only, then:
   ```bash
   cd ~/.config/opencode-openagent && npm install oh-my-openagent@latest   # builds dist/
   ```
   (machine-local install step — see docs; reproduce on each new machine.)

2. **opencode 1.17.8 can't resolve the bare plugin name.** With `"oh-my-openagent"`
   in the `plugin` array, opencode 1.17.8 silently fails to load it (it never adds
   it to its managed package.json; bare-name resolution is broken in this env), so
   it falls back to the stock `build`/`glm-5` agent. Fix: register the plugin by
   **`file://` path to omo's built entry** instead — loads directly like a local
   `.ts` plugin:
   `file://$HOME/.config/opencode-openagent/node_modules/oh-my-openagent/dist/index.js`
   The openagent `modify_opencode.json.tmpl` emits this via `{{ "{{" }} .chezmoi.homeDir {{ "}}" }}`.

### Status — WORKING
- `opencode` → vanilla (verified: default agents, MCPs, Go models all pong).
- `openagent` → omo loaded; **default agent is Sisyphus**, routed to
  `opencode-go/deepseek-v4-pro` (verified `pong`). All 11 agents assigned to
  smoke-tested Go models; `claude_code` discovery disabled; `runtime_fallback` on.
- Routing is currently **all-OpenCode-Go** (every model verified working). Pending
  refinement: promote GPT-native seats to `openai/gpt-5.5` (Codex sub, re-authed
  2026-06-19) and add a **Cursor Pro** orchestrator (`opencode-cursor` plugin +
  `CURSOR_API_KEY`) per `docs/opencode-profiles.md`.

NOTE on Claude: Anthropic **subscription OAuth** in opencode is server-blocked
(Jan 2026) + a ToS violation. The supported flat Claude path is **Cursor Pro** via
`opencode-cursor` (official `@cursor/sdk`, low risk), exposing `cursor-acp/claude-4.6-opus`
etc. — not the banned OAuth hacks.

## 2026-04-10 — Disable Claude Code/Codex plugin discovery in oh-my-openagent

### Problem
oh-my-openagent imports Claude Code plugins into opencode, which brings along
all MCPs from `~/.claude.json` (pty-mcp, mcp-alchemy, tempograph, discord, etc.).
pty-mcp's `ssh_connect` tool has `oneOf` in its schema, which opencode's LLM API
validation rejects — blocking ALL messages with:
`Invalid schema for function 'pty-mcp_ssh_connect'`

### Solution

**`dot_config/opencode/modify_oh-my-openagent.json`**:
- Added `claude_code` block with all discovery flags set to `false`:
  mcp, commands, skills, agents, hooks, plugins
- This prevents oh-my-openagent from importing anything from Claude Code or Codex
  into opencode, keeping the tool ecosystems fully isolated

**`dot_config/opencode/modify_opencode.json`**:
- Reverted temporary pty-mcp disable (no longer needed with discovery off)

**`dot_zshenv.tmpl`**:
- Added `OPENCODE_DISABLE_EXTERNAL_SKILLS=true` — opencode hardcodes
  `EXTERNAL_DIRS = [".claude", ".agents"]` and scans `skills/**/SKILL.md` in
  those dirs under `$HOME`. This picks up all Claude Code plugin skills
  (superpowers, discord, plugin-dev, etc.) from `~/.claude/plugins/cache/`.
  The env var disables this scan entirely, keeping opencode's skill list
  isolated to oh-my-openagent's own skills and any configured in opencode.json

## 2026-04-10 — Sync modify_oh-my-openagent.json with upstream

### Problem
Running `bunx install oh-my-openagent` updated the deployed
`~/.config/opencode/oh-my-openagent.json` with new fields (fallback_models on
most agents/categories, new `sisyphus-junior` agent). The chezmoi modify script
didn't have these fields, so the next `chezmoi apply` would strip them out.

### Solution

**`dot_config/opencode/modify_oh-my-openagent.json`**:
- Added `fallback_models` to agents: sisyphus, oracle, explore,
  multimodal-looker, prometheus, metis, momus, atlas
- Added new agent: `sisyphus-junior` (opencode-go/kimi-k2.5 with fallbacks)
- Added `fallback_models` to categories: ultrabrain, quick, unspecified-low,
  unspecified-high, writing
