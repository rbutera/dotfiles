# npm/pnpm config changes log

## 2026-08-20 — Upgrade Node 24.16.0 → 26.7.0 (global toolchain)

### Context
Node 26 is Current (LTS lands 2026-10-28). Upgraded the local machine + global toolchain now; deployed/containerised projects stay on their pinned versions until 26 goes LTS. No project had a hard `^24`-style engines pin — all are `>=18`/`>=22` ranges, 26-compatible.

### Changes
- **`dot_tool-versions`** + **`.tool-versions`** (chezmoi source dir): `nodejs 24.16.0` → `26.7.0`. Deployed `~/.tool-versions` via targeted `chezmoi apply ~/.tool-versions` (static file, no 1Password needed).
- **`run_once_12_install_node.sh`**: bumped `NODE_VERSION="22.18.0"` → `"26.7.0"`. This script was a **landmine** — it runs `asdf set --home nodejs "$NODE_VERSION"`, so if it ever reran it would have forced global node back to **22.18.0**. The `.chezmoiignore` globs (`*_setup_node.sh`, `*_install_node.sh`) that were meant to disable it don't match the actual filenames, so it's live. Only the version string was changed (per CLAUDE.md: don't restructure run_once scripts); the ignore-glob mismatch and the run_once_10/run_once_12 redundancy are left as-is for a future dedicated pass.
- **`~/.default-npm-packages`** (new, NOT chezmoi-managed — lives outside the source): created from the live global node_modules listing so asdf auto-reinstalls globals on every future version switch. Previously absent, which is why version bumps silently orphaned all global CLIs (see 2026 orphan runbook below).

### Global CLI reinstall
`asdf install nodejs 26.7.0` auto-reinstalled all 25 globals via `~/.default-npm-packages`, then `asdf reshim nodejs`. All 25 present, zero `engine-strict` failures. Reinstall pulls **latest** (not the previously-pinned versions) — notable jumps: `typescript` 6.0.3 → 7.0.2, `@openai/codex` 0.144.1 → 0.147.0, `@fission-ai/openspec` 1.4.1 → latest, `@tobilu/qmd` → 2.5.3, `mcporter` → 0.13.5. This supersedes the manual per-package orphan runbook — the `.default-npm-packages` file now handles it automatically.

### Verification
- `~/.asdf/shims/node` → v26.7.0; `asdf current nodejs` → 26.7.0; `~/.vite-plus/bin/node` wrapper auto-tracks → v26.7.0.
- 12 LaunchAgents unpinned from the versioned node path (see `logs/launchagents.md`); `decisions-refresh` observed running live on node 26 via shim under launchd.
- pnpm (10.32.1) and bun (1.3.14) globals live in their own dirs (`~/Library/pnpm`, `~/.bun`), untouched by the switch.

### Not done (deliberate)
- Old asdf installs `22.18.0` and `24.18.0` left in place as rollback safety; remove later with `asdf uninstall nodejs 24.16.0` etc. once 26 is proven over a few days.
- Deployed/containerised projects (opentabs-fork, lumiere Dockerfiles, anomalyco/opencode, hurdle/vercel, camofox-browser, claude-code-leaked) still pin node 20/22/24 in CI + Docker — leave until 26 LTS (Oct 2026), optionally add 26 to CI matrices early for warning.
- `sh.tokenmaxx.daemon.plist` (chezmoi-managed) pins bun 1.3.14 the same way — same disease, different runtime; deferred with the bun upgrade.

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

## 2026-07-14 — Convert `~/.npmrc` to a modify script; stop tracking the auth token

### Problem
`private_dot_npmrc.tmpl` rendered the registry auth token from 1Password
(`op://Private/npm auth/credential`). A local `npm login` rotated the token
(deployed `…0OghvD`, mtime 07-11) but 1Password was never updated (item still
`…0fxfxI`, updated 06-22). Result: perpetual drift, and any `chezmoi apply`
would have clobbered the working token with the stale 1Password one.

### Fix
- Retired `private_dot_npmrc.tmpl`; added **`modify_private_dot_npmrc`** (plain
  bash, no templating — no 1Password dependency).
- The modify script emits the authoritative supply-chain directive block
  (`min-release-age=7`, `save-exact`, `engine-strict`, `strict-ssl`, `audit`,
  etc. + the `# Supply-chain protection` comment) and then preserves **every
  `^//` registry line** (auth tokens, `:always-auth`, …) verbatim from the
  existing file via `printf '%s\n' "$current" | grep -E '^//' || true`.
- Net effect: chezmoi owns the config knobs; the auth token is owned by
  `npm login`/`npm token` and never touched. No token in chezmoi *or* 1Password.
  `private_` prefix keeps `~/.npmrc` at 0600. On a fresh machine (no existing
  file) the grep is a harmless no-op — run `npm login` to populate the token.

### Note
This supersedes the token-management half of the 2026-05-23 `dot_npmrc` design.
The supply-chain directives are unchanged; only the auth line is now untracked.

## 2026-08-18 — Global HTML/CSS parser deps for impeccable (portable via run_onchange)

**Problem:** The impeccable plugin needs `htmlparser2`, `css-select`, `css-tree`, and `domutils` available as global npm modules. Installing them by hand on one machine doesn't propagate to other dev machines.

**Change:** Added `run_onchange_install-npm-globals.sh` to the chezmoi source. It holds a `PACKAGES` array and installs only the missing ones (`npm ls -g` check, idempotent). Because it's a `run_onchange_` script, chezmoi re-runs it on every machine whenever the package list is edited — adding a future global package is a one-line edit to the array. Ran it on this machine: all four packages installed (htmlparser2@12.0.0, css-select@7.0.0, css-tree@3.2.1, domutils@4.0.2).

**Note:** No `NODE_PATH` export was added. If impeccable fails to `require()` these despite the global install, add `export NODE_PATH="$(npm root -g)"` to `dot_zshenv.tmpl`.

## 2026-08-20 — Recovered the impeccable npm-globals script after a diverged-pull reset

**Context:** A local commit (`idk`, 46cd9f4) that carried `run_onchange_install-npm-globals.sh` was dropped during a `git reset --hard origin/main` reconciliation (local `main` had lost its upstream and diverged; origin was cleaner on every other file). Audit of the dropped commit found this script + the entry above were the only unique, still-wanted artifacts on it — `impeccable` is referenced nowhere in the repo, but Rai confirmed it's still in use. Restored the script verbatim from `46cd9f4` and re-added the log entry above. Everything else in `idk` was either superseded by newer live edits (superpowers/plugins) or comment-only (`permissions.allow` was documented but never implemented in the jq body).
