# Obsidian sync config changes log

## 2026-04-12 — Migrate workspace-navi sync to new `navi` vault at `~/navi`

### Problem

Navi migrated from an openclaw agent to an ark agent as part of the broader
workspace reorg. Canonical home moved from `~/.openclaw/workspace-navi` to
`~/navi`. The launchd-managed obsidian-headless sync
(`~/Library/LaunchAgents/com.rai.obsidian-sync-navi.plist`) was *supposed* to
be repointed during that migration but never was in practice.

Symptoms:

- `launchctl list | grep obsidian-sync-navi` showed `-  3  com.rai.obsidian-sync-navi`
  (no PID, exit 3) — the job was throttle-looping under `KeepAlive`.
- `/Users/rai/.logs/obsidian-sync-navi.log` was 1.3 MB of the same line:
  `No sync configuration found for /Users/rai/navi — Run 'ob sync-setup' first.`

Root cause: the plist `ProgramArguments` already passed `--path /Users/rai/navi`,
but the local sync config at
`~/.obsidian-headless/sync/5adf787e183ace5c0cf0349fa75a9351/config.json`
still had `"vaultPath": "/Users/rai/.openclaw/workspace-navi"`. `ob-sync` looks
up the config by matching `--path` against the stored `vaultPath`, and nothing
matched.

### Solution

Rather than in-place rewrite the old config (and risk the old vault's stale
`state.db` reconciling against the new local tree), a clean-slate approach:

1. **Left the old sync config in place** as a backup —
   `~/.obsidian-headless/sync/5adf787e183ace5c0cf0349fa75a9351/` (vault
   `workspace-navi`, path `~/.openclaw/workspace-navi`) is untouched. Original
   vault content still lives at the old path for posterity.
2. **Created a new remote vault** `navi` (Europe region,
   `f27f96f6f0523159de22584a1bb33d9c`) via the Obsidian GUI — user-side step.
3. **Ran `ob sync-setup --vault navi --path /Users/rai/navi --device-name nimbus`**
   to register the new local→remote binding — user-side, since `ob` reads the
   encryption password from the controlling tty.
4. **Plist untouched** — `com.rai.obsidian-sync-navi.plist` was already pointed
   at `/Users/rai/navi` from the earlier (never-completed) migration.

**Exclusion tuning** (two false-start sync runs uncovered junk in the tree):

Ran `ob sync-config --path /Users/rai/navi --excluded-folders '.git,.playwright-mcp,node_modules,workspace/state'`.
The `workspace/state` exclusion is the important one — it contains ~274 MB of
Chrome profile data from claude-usage-chrome / claude-cookie-probe
(IndexedDB, GPUCache, extension bundles, leveldb) used by browser automation
skills, none of which belongs in an Obsidian vault.

Restart procedure (after exclusion fix):
```bash
true >| /Users/rai/.logs/obsidian-sync-navi.log
launchctl bootout gui/$(id -u)/com.rai.obsidian-sync-navi
launchctl bootstrap gui/$(id -u) /Users/rai/Library/LaunchAgents/com.rai.obsidian-sync-navi.plist
```

Note on zsh: `: > file` to truncate trips `noclobber`; use `true >| file`
(explicit clobber) instead.

### Verification

- `launchctl list | grep obsidian-sync-navi` → `3227  0  com.rai.obsidian-sync-navi`
  (real PID, last exit 0 — no throttle loop).
- `tail -f /Users/rai/.logs/obsidian-sync-navi.log` shows actual note uploads
  (`workspace/memory/*.md`, `skills/*/SKILL.md`) with no `node_modules/`,
  `Profile 1/IndexedDB`, or `workspace/state/` paths.
- `grep -c -iE 'error|failed' /Users/rai/.logs/obsidian-sync-navi.log` → `0`.
- `ob sync-list-local` shows both the preserved old config and the new one
  side-by-side.

### Notes / future cleanup

- The old `workspace-navi` remote vault and local config are intentionally
  preserved as a safety net. Once the new `navi` sync has run to steady state
  and been verified, both can be torn down (`ob sync-unlink` locally; delete
  remote via the Obsidian web UI).
- This log lives in the dotfiles repo but the subject (`~/navi`,
  `~/.obsidian-headless/`, the plist) is runtime state, not chezmoi-managed
  config. Nothing here needs `chezmoi apply`.
- `ob sync-config` only supports *exclude* lists, not include lists. If
  `~/navi` grows more runtime/state subdirs in the future, they'll need to be
  added to `--excluded-folders` explicitly.
