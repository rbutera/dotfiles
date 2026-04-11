# opencode config changes log

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
