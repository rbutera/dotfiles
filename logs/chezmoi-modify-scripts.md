# chezmoi modify scripts changelog

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
