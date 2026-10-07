# 1Password

## 2026-10-07 — Private vault to Rai vault, service accounts

**Problem:** agents could not run `chezmoi apply` without Rai's interactive 1Password session, and service accounts cannot read the built-in Private vault.

**Changed:** Rai moved his items from Private into a new custom `Rai` vault in the 1Password app. Every `op://Private/` reference in the source (templates, `bin/executable_add-api-key`, the add-mcp-server skill, CLAUDE.md/AGENTS.md) now reads `op://Rai/` (commit d02e5c7); `logs/` left as history. Per-agent service accounts: Navi on nimbus (read+write on Rai and dev, no share), Tilly on latios. Tokens live in `~/.config/op/<agent>-token` (600, outside git). Verified on nimbus: the Navi token lists Rai and dev and reads items from both (byte counts only). Still to do: the agent-side chezmoi service-mode config. Design: ~/expedition/1Password Service Account Design.md.
