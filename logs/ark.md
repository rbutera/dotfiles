# Ark workspace config changes log

## 2026-07-13 — Capture live navi/ark.json drift into the template (chezmoi-sync)

### Problem
The deployed `~/navi/ark.json` had evolved well beyond `navi/ark.json.tmpl` and
`chezmoi apply` would have reverted the live config. A jq-normalized diff showed
three real semantic additions in the deployed file the template lacked:
- `additionalPlugins` gained `.../lumiere/apps/potara-cc` (verified still present
  in lumiere/apps — **not** renamed to a "decision inbox"; the dir name is
  unchanged).
- `discord.channelSource.pluginDir` changed `discord-text-plugin` → `ark-discord`.
- New `discord.snooze` (quietHours 22:00–08:00 Europe/London) and `discord.recap`
  (`mode: on-return`, `channel: navi`) blocks.

### Changes
- Rebuilt `navi/ark.json.tmpl` from the live `~/navi/ark.json`, re-inserting the
  `{{ .chezmoi.homeDir }}` substitutions for the six templated lumiere/navi paths
  (`/Users/rai/dev/lumiere` and `/Users/rai/navi` prefixes). Left `~/notes/...`,
  `${OPENCLAW_DISCORD_NAVI}`, and `/Volumes/...` literals untouched.

### Verification
`chezmoi execute-template < navi/ark.json.tmpl | diff - ~/navi/ark.json` →
byte-identical. Deployed file untouched (respect-deployed).

## 2026-06-24 — Reconcile ark config drift (chezmoi-sync)

### Problem

A `/chezmoi-sync` pass found two ark configs drifted between deployed and source:

1. **`~/.config/ark/config.json`** — deployed had `authMode: "keychain"` on the
   `personal` account only; source (per commit `18470c3`) had it on `work` only.
2. **`~/navi/ark.json`** — the deployed file had live config the source template
   never captured (an `ark-email-plugin` entry, an `email` block, a discord
   `groups` entry, and `textPlugin.recapChannelId`).

### Changes

- **`dot_config/ark/config.json.tmpl`**: Added `authMode: "keychain"` to the
  `personal` account so **both** accounts (personal + work) now use keychain
  auth, per Rai's call. Applied to deployed.
- **`navi/ark.json.tmpl`**: Merged the deployed-only config back into the source
  template (keep-deployed direction) — added `ark-email-plugin` to
  `mainOnlyPlugins`, the `email` block (`navi@e8n.dev`, displayName, whitelist),
  the discord `groups` entry (`1508801011760762940`, `requireMention:false`),
  and `textPlugin.recapChannelId`. Verified the rendered template now matches the
  live file (empty diff). Paths kept as `{{ .chezmoi.homeDir }}` for portability.

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

## 2026-07-17 — ark.json: discord voice bridge path renamed (ark-discord unification)

### Problem

Lumiere finished unifying the Discord plugin under `apps/ark-discord`, and the old
`apps/discord-voice-plugin` package (the thin voice MCP bridge) was renamed to
`apps/ark-discord-voice-bridge`. Both ark.json templates still pointed
`mainOnlyPlugins` at the old path.

### Changes

- **`navi/ark.json.tmpl`** and **`focused/ark.json.tmpl`**: `mainOnlyPlugins` entry
  `apps/discord-voice-plugin` → `apps/ark-discord-voice-bridge`.
- Left `extraClaudeArgs` `server:plugin:discord-voice:discord-voice` unchanged on
  purpose: `discord-voice` is the Claude plugin id (wire identifier in transcripts),
  not the directory name — the rename deliberately kept it.
