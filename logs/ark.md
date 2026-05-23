# Ark workspace config changes log

## 2026-05-23 — Manage ark.json files via chezmoi

### Problem

`~/navi/ark.json` and `~/focused/ark.json` were edited directly in the workspace directories, outside of chezmoi management. This made them drift across machines and invisible to the dotfiles source of truth.

### Changes

- **`navi/ark.json.tmpl`**: New chezmoi source template for `~/navi/ark.json`. Hardcoded `/Users/rai/` paths replaced with `{{ .chezmoi.homeDir }}` for portability.
- **`focused/ark.json.tmpl`**: New chezmoi source template for `~/focused/ark.json`. Same `homeDir` templating. Single-brace `{today}`/`{yesterday}` Ark runtime placeholders left as-is (chezmoi only interprets double-brace).
- **`CLAUDE.md`**: Added `navi/` and `focused/` to the repository structure listing.
- **`~/dev/lumiere/CLAUDE.md`** (= `AGENTS.md`): Added chezmoi-managed files table covering `ark.json` (navi/focused) and impulse `jobs.json`.
- **`~/dev/lumiere/apps/ark/AGENTS.md`**: Added chezmoi guidance to Key Concepts.
- **`~/dev/lumiere/apps/impulse/AGENTS.md`**: Added chezmoi-managed config section for `jobs.json`.
