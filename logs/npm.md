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

## 2026-06-12 — Node-24 global-CLI orphan class: detection + runbook

### Problem
After the 22→24 bump, several global npm CLIs silently re-orphaned: their asdf shims still pointed at the node-22 install, so invoking them under node 24.16.0 returned `No version is set for command <x>` (or exit 126). These are on-demand CLIs (not launchd-managed), so they fail *silently* only when invoked — nothing crash-loops, the next call just errors. Confirmed across a cluster: `obsidian-headless` (lz3w), `opentabs` (g95z), `ccline`, `claudex`. (`qmd` was suspected but is fine — it resolves to the Homebrew binary `/opt/homebrew/bin/qmd 2.0.1`, not the npm copy.)

### Fix (trivial, repeatable)
For each orphaned CLI: reinstall the providing package under the active node, then reshim:
```bash
npm install -g @cometix/ccline @kunwarshah/claudex   # recreates the bin symlink under node 24
asdf reshim nodejs                                    # regenerates the shims
ccline --version && claudex --version                 # verify they resolve
```

### Runbook: after ANY `asdf` node default bump
Reinstall the global CLIs so their shims re-point at the new node. The full set (from the 2026-05-23 entry): `@bitbonsai/mcpvault`, `@cometix/ccline`, `@kunwarshah/claudex`, `@fission-ai/openspec`, `@openai/codex`, `@opentabs-dev/cli` (+ slack/teams plugins), `@tobilu/qmd`, `humanizer`, `mcporter`, `obsidian-headless`, `obsidian-mcp`. Then `asdf reshim nodejs`. This prevents the silent-orphan class from recurring on the next upgrade.
