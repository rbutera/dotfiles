# npm/pnpm config changes log

## 2026-05-23 — Add global .npmrc with supply-chain hardening + upgrade Node to 24

### Problem
No global `.npmrc` existed. Wanted supply-chain protection to prevent installing npm packages published less than 7 days ago. Also, npm 10.x (bundled with Node 22) didn't support the `min-release-age` config option — that requires npm 11.10.0+ (Node 24).

### Changes
- **`dot_npmrc`** (new): Created chezmoi-managed `~/.npmrc` with supply-chain hardening:
  - `min-release-age=7` — npm 11.10.0+, rejects packages newer than 7 days
  - `minimum-release-age=10080` — pnpm 10.16+, same but in minutes (7 days)
  - `save-exact=true` — pins exact versions, no `^`/`~` ranges
  - `engine-strict=true` — fail on incompatible engines
  - `package-lock=true` — always generate lockfile
  - `strict-ssl=true` — enforce TLS cert validation
  - `audit=true` / `audit-level=high` — auto-audit on install
  - `fund=false` — suppress funding noise
  - `ignore-scripts=true` — block lifecycle scripts (primary supply-chain attack vector)
- **`dot_tool-versions`**: Bumped `nodejs 22.18.0` → `24.16.0` (ships npm 11.13.0)
- **`.tool-versions`** (chezmoi source dir): Also bumped to `24.16.0` so asdf resolves correctly from CWD
- Reinstalled all global npm packages on Node 24: `@bitbonsai/mcpvault`, `@cometix/ccline`, `@fission-ai/openspec`, `@openai/codex`, `@opentabs-dev/cli`, `@opentabs-dev/opentabs-plugin-slack`, `@opentabs-dev/opentabs-plugin-teams`, `@tobilu/qmd`, `humanizer`, `mcporter`, `obsidian-headless`, `obsidian-mcp`
- pnpm global packages unaffected (stored separately in `~/Library/pnpm/global/`)
