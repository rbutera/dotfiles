# Codex config changes log

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
