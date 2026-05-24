# chezmoi modify scripts changelog

## 2026-05-15 — Exclude chisel, tempograph, oss-autopilot on Windows

### Problem
Three MCP servers fail on Windows:
- **chisel** — Unix-only Rust binary (POSIX syscalls, Unix shell whitelist). Not installable on Windows.
- **tempograph** — Python dependency `py-rust-stemmers` fails to compile on Windows (needs maturin + Rust build chain).
- **oss-autopilot** — fails to connect on Windows.

### Changes
- **`run_onchange_apply-claude-json-windows.ps1`**: Removed chisel, tempograph, and oss-autopilot from `$baseMcpsJson`. They remain in the bash `modify_dot_claude.json.tmpl` for Linux/macOS.
- **`dot_codex/modify_private_config.toml`**: Added `sys.platform == "win32"` guard that pops the three servers from `BASE["mcp_servers"]` on Windows.

## 2026-04-10 — Force open-websearch to stdio-only in Codex

### Problem

`open-websearch` defaults to `MODE=both`, which starts MCP stdio and also an HTTP server on port `3000`.
When another process already owns `3000`, startup crashes with `EADDRINUSE` after stdio connects, and Codex reports a closed connection during MCP initialize.

### Changes

- `dot_codex/modify_private_config.toml`: added `env.MODE = "stdio"` for the `open-websearch` MCP entry so Codex launches it without the extra HTTP listener

## 2026-04-10 — Fix tempograph entrypoint, remove mcp-alchemy from Claude config

### Problem
Three MCP servers were failing with `-32000: connection closed` in Claude Code (and opencode):
- **tempograph** — wrong entrypoint `tempograph` (CLI, requires `repo` arg) instead of `tempograph-server` (MCP stdio server). Same bug was already fixed in the codex config on 2026-04-08 but never applied to the claude config.
- **mcp-alchemy** — no `DB_URL` env var set, so it starts and immediately exits. Already removed from codex for the same reason.
- **open-websearch** — was actually working fine, likely a transient npx issue.

### Changes
- `modify_dot_claude.json.tmpl`: changed tempograph args from `["--from", "tempograph[full]", "tempograph"]` to `["--from", "tempograph[full]", "tempograph-server"]`
- `modify_dot_claude.json.tmpl`: removed `mcp-alchemy` entry entirely (no database to connect to)

## 2026-04-08 -- Make MCP server lists authoritative (replace, not merge)

### Problem
The modify scripts for both Claude Code and Codex used additive merge for MCP servers. Removing an MCP server from the chezmoi source had no effect on the deployed config because the old key survived the merge. Stale entries like `mcp-redis` and `url` fields persisted forever.

### Solution/Fix
- **Claude Code** (`modify_dot_claude.json.tmpl`): changed jq from `'.mcpServers = ((.mcpServers // {}) * $base)'` to `'.mcpServers = $base'`. Base is now the sole source of truth for MCP servers.
- **Codex CLI** (`dot_codex/modify_private_config.toml`): after the deep_merge, override `mcp_servers`, `model_providers`, and `plugins` keys entirely from BASE. Free keys (`projects`, `notice`) still survive the merge as before.

This means: add an MCP server to chezmoi source, it appears. Remove it, it disappears. No more stale ghosts.

## 2026-04-08 -- Fix tomllib import on macOS (Python 3.9) in Codex modify script

### Problem
`dot_codex/modify_private_config.toml` imports `tomllib` which requires Python 3.11+. macOS system Python is 3.9.6, so `chezmoi apply` fails with `ModuleNotFoundError: No module named 'tomllib'`.

### Solution/Fix
Added try/except fallback chain: try `tomllib` (3.11+) first, then `tomli` backport, then fail with a clear error message. Installed `tomli` and `tomli-w` via pip for macOS system Python (`/usr/bin/python3 -m pip install tomli tomli-w`). On Arch this was fine because `python-tomli-w` package was already installed and Python is 3.12+.

## 2026-04-08 -- Fix osRelease crashes on macOS across multiple templates

### Problem
Several templates accessed `.chezmoi.osRelease.id` or `.chezmoi.osRelease.idLike` without first checking if `.chezmoi.os == "linux"`. On macOS, `.chezmoi.osRelease` doesn't exist at all (it's a Linux-only map), causing `chezmoi apply` to fail with: `map has no entry for key "id"`.

### Solution/Fix
Added `eq .chezmoi.os "linux"` as the outer guard in `and` chains before any `.chezmoi.osRelease` access. Go templates short-circuit `and`, so the `osRelease` access is never evaluated on macOS.

Files fixed:
- `modify_dot_claude.json.tmpl:58` (arch-linux MCP server block)
- `dot_config/ghostty/config.tmpl:12` (GeistMono font on Arch)
- `dot_aliases.tmpl:196` (BALDING_GATE_DIR on Arch)

Files already safe (already inside `{{ if eq .chezmoi.os "linux" }}` blocks):
- `dot_aliases.tmpl:227`, `dot_zprofile.tmpl:132`

Files not fixed (run_once scripts are broken/ignored anyway):
- `run_once_01`, `run_once_03`, `run_once_03b` (all already gated or never run on macOS)

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
