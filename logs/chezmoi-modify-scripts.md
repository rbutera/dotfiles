# chezmoi modify scripts changelog

## 2026-04-08 — Add Tier 1 MCP servers + Chisel to modify scripts

### Changes
Added the following MCP servers to both `modify_dot_claude.json` and `dot_codex/modify_private_config.toml`:
- **mcp-alchemy** — SQLAlchemy-based multi-DB (Postgres, MySQL, SQLite). Needs `DB_URL` env var.
- **mcp-redis** — Official Redis MCP. Defaults to localhost:6379.
- **tempograph** — Code graph context engine, 24 tools, tree-sitter for 170+ languages. No API keys.
- **oss-autopilot** — Open source contribution manager, PR tracking, CI diagnosis. Uses `gh` auth.
- **pty-mcp** — Persistent PTY/SSH sessions. Single Go binary installed to ~/bin.
- **chisel** — File ops with 20-100x token savings via diffs. Rust binary in ~/bin, `--stdio` mode (no HTTP/auth).
- **better-notion-mcp** — Notion integration with 77% token reduction. Needs `NOTION_TOKEN`.

Also updated `dot_claude/modify_settings.json` with newly enabled plugins (superpowers, skill-creator, claude-md-management, commit-commands, serena, plugin-dev, slack, chrome-devtools-mcp, mcp-server-dev).

### Binaries installed
- `~/bin/pty-mcp` + `~/bin/ai-tmux` (from pty-mcp installer)
- `~/bin/chisel` (from GitHub releases, linux-x86_64)

## 2026-04-08 — Add modify script for ~/.claude.json (global MCP servers)

### Problem
Claude Code stores global MCP servers in `~/.claude.json`, not `~/.claude/settings.json`. The `add-mcp` tool writes to this file, but it also contains runtime state (numStartups, tipsHistory, etc.) that shouldn't be tracked.

### Changes
- Created `modify_dot_claude.json` — shell script using `jq` to merge managed `mcpServers` into `~/.claude.json`
- Managed fields: `mcpServers` only
- Free fields: everything else (runtime state)
- Also updated `dot_codex/modify_private_config.toml` to include `command`/`args` for open-websearch (was missing, only had `url`)
- Updated `docs/mcp.md` to document the new modify script

## 2026-04-08 — Convert Claude Code and Codex CLI configs to modify scripts

### Problem
Static chezmoi-managed config files for Claude Code (`dot_claude/settings.json`) and Codex CLI (`dot_codex/private_config.toml.tmpl`) were always out of sync with the live configs on the system. Both tools modify their own config files at runtime — Claude Code adds per-project permissions, Codex adds trusted projects and migration notices. Every `chezmoi apply` would overwrite these runtime additions.

### Solution
Replaced static config files with chezmoi `modify_` scripts. These scripts receive the current file contents on stdin, merge in managed base config, and output the result — preserving app-managed fields while ensuring base config is consistent across machines.

### Changes

**Claude Code** (`dot_claude/modify_settings.json`):
- Shell script using `jq` for JSON merging
- Managed fields: `cleanupPeriodDays`, `enabledPlugins`
- Free fields (preserved): `permissions`, `model`, `attribution`, `skipDangerousModePermissionPrompt`, and anything else the app adds
- `enabledPlugins` merge is additive — base plugins always present, per-machine extras preserved

**Codex CLI** (`dot_codex/modify_private_config.toml`):
- Python script using `tomllib` (read) + `tomli_w` (write) for lossless TOML round-tripping
- Uses `/usr/bin/python3` shebang (not `/usr/bin/env python3`) because asdf's Python shim doesn't see system site-packages where `tomli_w` is installed
- Managed fields: top-level settings, `sandbox`, `mcp_servers`, `model_providers`, `plugins`
- Free fields (preserved): `projects` (machine-specific trusted paths), `notice` (app-managed migration state)
- Deep merge: base config wins for managed keys, existing config adds free keys

### Removed
- `dot_claude/settings.json` (replaced by modify script)
- `dot_codex/private_config.toml.tmpl` (replaced by modify script)

### Dependencies
- `jq` (for Claude Code modify script)
- `python-tomli-w` system package (for Codex modify script) — installed via `paru -S python-tomli-w`

### Notes
- Both scripts are idempotent — running `chezmoi apply` multiple times produces no diff
- To add a new MCP server to Codex across all machines, add it to the `BASE` dict in the modify script
- To add a new Claude Code plugin across all machines, add it to the `base` JSON in the modify script
- `yq` was evaluated for TOML but rejected — it strips quotes from keys and reformats arrays, breaking Codex's expected format
