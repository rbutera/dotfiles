# 1Password

## 2026-10-07 — Private vault to Rai vault, service accounts

**Problem:** agents could not run `chezmoi apply` without Rai's interactive 1Password session, and service accounts cannot read the built-in Private vault.

**Changed:** Rai moved his items from Private into a new custom `Rai` vault in the 1Password app. Every `op://Private/` reference in the source (templates, `bin/executable_add-api-key`, the add-mcp-server skill, CLAUDE.md/AGENTS.md) now reads `op://Rai/` (commit d02e5c7); `logs/` left as history. Per-agent service accounts: Navi on nimbus (read+write on Rai and dev, no share), Tilly on latios. Tokens live in `~/.config/op/<agent>-token` (600, outside git). Verified on nimbus: the Navi token lists Rai and dev and reads items from both (byte counts only). Still to do: the agent-side chezmoi service-mode config. Design: ~/expedition/1Password Service Account Design.md.

## 2026-10-07 (later) — chezmoi-agent wrapper, focused vault retired

**Changed:** added `bin/executable_chezmoi-agent` (service-mode chezmoi for agents, token from `~/.config/op/<agent>-token`). Repointed the six `onepasswordDetailsFields ... "Private"` calls to `"Rai"` (the first pass only caught `op://` refs). The `focused` vault is retired: Flaude Discord moved to Rai, and the Cursor API key and Claude Code OAuth token refs were removed (Rai no longer uses them). Documented in CLAUDE.md/AGENTS.md. Verified: `chezmoi-agent --agent navi status` renders every template (rc 0), and the impulse .env diff shows only comment changes, so the values are identical through the service account.
