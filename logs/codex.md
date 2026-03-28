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
