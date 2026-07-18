# chezmoi config changes log

## 2026-07-18 — latios: resolve 47-file merge conflict by taking remote main wholesale

### Context
`git pull` on latios had left a merge in progress with 47 conflicted files —
nearly every tracked file showed `AA` (added-by-both). Root cause: the repo's
history was rewritten at some point, so latios's local `main` (418 commits) and
remote `main` (543 commits) only shared the ancient 2022 base `d4084ef "add
.tmux"`, making git treat every file as independently added on both sides.

### Diagnosis (patch-equivalence, not eyeballing 47 diffs)
- `git rev-list --cherry-pick` showed the two histories are mostly rebased
  duplicates of each other. Local-unique commits since 2026-04: **zero** —
  GELATO_API_KEY, narrate TTS switch, impulse kinto jobs etc. all exist on
  remote under different hashes.
- Only 3 genuinely local-unique non-merge commits, all from **2022-07** ("fix
  github auth token", "fix hosts", "add fig and .ssh") — long superseded.
- Local newest commit 2026-06-01 vs remote 2026-07-17 → latios was a strict
  stale subset; remote is canonical (kinto/nimbus work).

### Resolution
- `git read-tree -u --reset MERGE_HEAD` — set index + worktree to the remote
  tree verbatim, keeping the merge state, then committed (f95d443). Local
  history is preserved as the merge's first parent; nothing force-pushed, no
  `reset --hard`.
- Pushed to origin so future pulls on any machine are ordinary merges.

### Follow-up
- `chezmoi diff`/`apply` on latios after this — the source jumped ~6 weeks, so
  deployed configs will drift until applied (needs a 1Password session).

## 2026-07-14 — chezmoi-sync: kill recurring claude.json / npmrc drift + merge ark.json

### Context
`/chezmoi-sync` run. Detector flagged 4 drifted files, all templates:
`.claude.json`, `focused/ark.json`, `.env`, `.npmrc`. Two were *recurring*
drift (self-inflicted by tooling), so the fix was structural, not a one-off
reconcile — Rai's directive was "make the trailing newline a non-factor" and
"convert npmrc into a modify script and leave the auth token out of it".

### `.claude.json` — permanent trailing-newline fix (modify script)
- Symptom: perpetual 1-byte drift. `modify_dot_claude.json.tmpl` ended with
  `jq`, which always emits a trailing newline; Claude Code rewrites
  `~/.claude.json` with **no** trailing newline → drifts every session.
- Fix: capture the `jq` output in `result=$(…)` (strips trailing newlines) and
  emit with `printf '%s' "$result"` (no newline). Output now byte-identical to
  Claude's own writes. Drift can't recur. (See chezmoi-modify-scripts.md.)

### `focused/ark.json` — merge (kept deployed + re-added hang-fix)
- Deployed (07-03) had diverged from source (07-01) *both ways*: deployed used
  `ark-discord` channelSource + had `snooze`/`recap`/`email` blocks but had
  **lost** the `--disallowedTools AskUserQuestion` hang-fix; source used
  `discord-text-plugin`, dropped those blocks, kept the hang-fix.
- Resolution (Rai's call): treat live 07-03 config as canonical, rewrite
  `focused/ark.json.tmpl` to match it (ark-discord, snooze, recap, email) **and**
  re-add `--disallowedTools AskUserQuestion`, then `apply --force` so the live
  file actually regains the hang-fix. Florence picks it up on next reload.

### `.env` — keep source (apply --force)
- Only diff was an additive comment block documenting why `ANTHROPIC_API_KEY` is
  intentionally absent (rank-3 API key would outrank the Max /login creds). No
  secret-value change. Applied; no source edit.

### `.npmrc` — converted to modify script, auth token now untracked
- Deployed npm token (07-11, `…0OghvD`) was **newer** than the 1Password item
  `op://Private/npm auth/credential` (06-22, `…0fxfxI`) — a local `npm login`
  rotated it, 1Password never caught up. Blind `apply --force` would have
  reverted npm auth to the stale token.
- Fix (Rai's call): retired `private_dot_npmrc.tmpl` (1Password-templated) for
  `modify_private_dot_npmrc`. It emits the managed supply-chain directive block
  and preserves any `^//` registry line (tokens/creds) verbatim from the
  existing file. Token is no longer tracked in chezmoi *or* 1Password → drift
  can't recur. `private_` prefix keeps 0600. (See npm.md.)

## 2026-07-13 — chezmoi-sync: finish `main` merge + reconcile deployed drift

### Context
Session started mid-merge (`git merge` of `origin/main`, 13 commits behind) with
a single conflict in `logs/codex.md`, followed by a full `/chezmoi-sync` run.

### Merge
- Resolved `logs/codex.md` by keeping **both** log entries newest-first
  (2026-07-13 sandbox-friction on top, then 2026-07-11 GPT-5.6 reasoning), then
  committed the merge (`8bb7a66`) and pushed. A stray `pull --rebase --autostash`
  re-triggered the same conflict; aborted the rebase back to the clean merge
  (I was already `ahead 3, behind 0`, so the pull was a no-op anyway).

### 1Password gate
- `op whoami` reports "no active session" (stale `OP_SESSION_personal` env var),
  but the **1Password desktop-app CLI integration** authorizes `op read`/`op vault
  list` directly — so templates render fine despite `whoami` failing. The sync
  detector only needs `chezmoi status` to succeed, which it does.
- The deployed `detect-drift.sh` was the **old** pre-merge version
  (`${CHEZMOI:-chezmoi}` + 20s timeout), so it errored `chezmoi-not-found`;
  ran `chezmoi status` directly instead. Applying Group A updated the deployed
  detector to the fixed `$CHEZMOI_SYNC_BIN`/180s version.

### Group A — un-applied merge (source authoritative; `apply --force`)
Deployed this machine's copies of the just-merged source (nothing deployed-side
to lose — all ` M`/new/benign-churn): `codex-teammate.md`, `settings.json`,
`detect-drift.sh`, `herdr/config.toml`, `.pi/agent/auth.json` (had to `mkdir -p
~/.pi/agent` first), `.ssh/config`, and the re-merge modify-scripts
(`.claude.json`, `.codex/config.toml`, `.config/impulse/jobs.json`).

### Group B — genuine deployed drift, kept deployed by updating source
- **`dot_tool-versions`**: `chezmoi add` — source said `bun 1.3.9`, deployed (and
  kinto) run `bun 1.3.14`. Kept deployed.
- **`dot_zshrc.tmpl`**: appended the `# >>> grok installer >>>` PATH/compinit
  block the grok installer had added to the live `~/.zshrc`.
- See `logs/ssh.md` (authorized_keys) and `logs/ark.md` (navi) for the other two.

### Residual
`.claude.json` still shows `MM` — a trailing-newline-only diff (jq emits `\n`,
Claude Code doesn't). Documented benign churn (see 2026-06-24 in `logs/claude.md`);
left as-is.

### Verification
Each Group B template re-rendered with `chezmoi execute-template` and `diff`-ed
byte-for-byte against its deployed file — all identical. Committed only the four
touched source paths (+ these logs); pushed.

## 2026-07-13 — Fix chezmoi-sync detector: `$CHEZMOI` env var collision

### Problem

`/chezmoi-sync` failed immediately with `ERROR | chezmoi-not-found`, even though
`chezmoi` was on PATH (`~/.asdf/shims/chezmoi`). The detector took its binary
path from an env override, `CHEZMOI="${CHEZMOI:-chezmoi}"` — but `CHEZMOI=1` was
already exported in the environment (chezmoi sets `CHEZMOI=1` in scripts it
runs, and the session inherited it). So the script resolved the binary to the
literal string `1`, and `command -v 1` failed the presence check.

### What changed

- **`dot_claude/skills/chezmoi-sync/detect-drift.sh`**: The override variable is
  now `CHEZMOI_SYNC_BIN` instead of `CHEZMOI`, with a comment explaining why the
  bare name is unusable. Applied to the deployed skill.

With the fix, the detector reaches `chezmoi status` and fails cleanly on the
1Password gate (exit 1, "multiple accounts found") rather than hanging. That gate
was then fixed separately — see logs/zshenv.md, 2026-07-13 (OP_ACCOUNT).

### Second bug: timeout far too short

Once 1Password was selecting an account correctly, the detector still reported
`STATUS_BLOCKED | need-op-session` — a false alarm. A full `chezmoi status` walk
renders every template and so pays one `op` round-trip per secret: measured at
**87s** on this repo with a perfectly healthy session. The detector's default
`STATUS_TIMEOUT` was 20s, so it tripped the timeout and blamed the op session.

- **`dot_claude/skills/chezmoi-sync/detect-drift.sh`**: default
  `CHEZMOI_SYNC_STATUS_TIMEOUT` raised 20s → 180s.

Both fixes verified together: the detector now runs from a clean shell with no
sign-in and no env overrides, listing drift in ~90s.

## 2026-07-01 — Bake the "never leave the source repo dirty" golden rule into CLAUDE.md + AGENTS.md

### Motivation

Rai's standing golden rule (2026-07-01): whenever an agent finds this chezmoi source repo dirty, it must commit and push it, never stash-and-forget. Previously this lived only in Florence's bd memory (`chezmoi-golden-rule`), so it depended on Florence remembering. Baking it into the repo's agent-guidance file makes any agent touching chezmoi (Claude Code, Codex, etc.) obey it without external memory (Brita filter).

### What changed

- Added a **"Golden Rule: never leave the source repo dirty"** section to `CLAUDE.md`, right after Agent requirements: inspect all drift (including un-authored), commit sane diffs with a clear message + push, surface suspicious diffs to Rai, never leave dirty.
- Created `AGENTS.md` as a **symlink to `CLAUDE.md`** so cross-tool agents (Codex and anything reading AGENTS.md) get the same guidance from a single source of truth (no duplication → no drift, fitting given the topic).

Both are plain files (no 1Password), safe to commit without a session.

## 2026-06-03 — Add io.focused.nightly-health launchd plist

### Motivation

The nightly system-health job (OpenSpec change `nightly-system-health`, tasks 6.1/6.2) needed a launchd plist managed via chezmoi so the schedule is version-controlled and deployed deterministically, but inert until manually armed.

### What changed

Added `Library/LaunchAgents/io.focused.nightly-health.plist` to the chezmoi source. This is a plain XML file (no 1Password template functions), so `chezmoi apply ~/Library/LaunchAgents/io.focused.nightly-health.plist` is safe to run without a 1Password session.

The plist configures:
- Label: `io.focused.nightly-health`
- ProgramArguments: `/bin/bash /Users/rai/focused/scripts/health/nightly-health.sh`
- StartCalendarInterval: five entries for Weekday 1-5 (Mon-Fri), Hour 7, Minute 0
- RunAtLoad: false (inert until armed)
- EnvironmentVariables: HOME, PATH (including .asdf/shims for node/ark), ARK_WORKSPACE_ROOT
- StandardOutPath/StandardErrorPath: `scripts/health/logs/nightly-health-launchd{,-error}.log`

### Arm / disarm

```bash
# Arm (deploy + load):
chezmoi apply ~/Library/LaunchAgents/io.focused.nightly-health.plist
launchctl load ~/Library/LaunchAgents/io.focused.nightly-health.plist

# Disarm (stop schedule, keep file):
launchctl unload ~/Library/LaunchAgents/io.focused.nightly-health.plist

# Verify:
launchctl list | grep nightly-health
```

Companion wrapper: `~/focused/scripts/health/nightly-health.sh` (runs run.sh first, then optional ark narration step, with overall deadline watchdog). Narration disabled pending task-0.4 spike.

## 2026-05-01 — Fix `chezmoi apply` failing with multiple 1Password accounts on WSL

### Problem

After adding a work 1Password account (`focusedlabs.1password.com`) on the WSL machine, `chezmoi apply` broke:

```
[ERROR] multiple accounts found. Use the --account flag or set the OP_ACCOUNT environment variable
chezmoi: template: dot_aider.conf.yml.tmpl:1:21: error calling onepasswordRead: /usr/bin/op signin --raw: exit status 1
```

chezmoi was calling `op signin --raw` without specifying `--account`. With only one account this was fine; with two accounts `op` refuses to guess. The `account = "my.1password.com"` setting in the local config wasn't being picked up — the URL format (`my.1password.com`) was wrong; `op` expects the shorthand domain (`my`).

### Fix

Edited `~/.config/chezmoi/chezmoi.toml` (local config, not the source template):

```toml
[onepassword]
account = "my"      # was "my.1password.com" — op uses the domain shorthand, not full URL
prompt = false      # skip op signin entirely; call op read directly using existing app sessions
```

`prompt = false` is the key change: it prevents chezmoi from calling `op signin --raw` and instead relies on existing 1Password sessions. Direct `op read` already works for both the personal (`op://Private/...`) and work (`op://focused/...`) vaults because the 1Password Windows app maintains sessions for both accounts.

The `/usr/bin/op` on this WSL machine is the Windows-app-integrated 1Password CLI (auth goes via a Windows GUI prompt), not a standalone Linux keychain binary.

## 2026-04-24 — Add claude-codex-bridge MCP (bidirectional Claude <-> Codex)

### Problem

The existing Codex Claude Code plugin (`codex:rescue`, etc.) felt unwieldy for quick cross-assistant collaboration. Wanted structured MCP tools for code reviews, plan critiques, and explanations that work in both directions — Claude calling Codex and Codex calling Claude.

### Solution

Forked [Dunqing/claude-codex-bridge](https://github.com/Dunqing/claude-codex-bridge) to `rbutera/claude-codex-bridge`. The bridge is a thin MCP translation layer: two stdio servers that shell out to `codex exec` / `claude -p` and parse JSON output.

Added to chezmoi:
- **Claude side**: `codex` MCP server in `modify_dot_claude.json.tmpl` running `npx claude-codex-bridge@0.3.1 serve codex`. Gives Claude 6 tools: `codex_query`, `codex_review_code`, `codex_review_plan`, `codex_explain_code`, `codex_plan_perf`, `codex_implement`.
- **Codex side**: `claude` MCP server in `modify_private_config.toml` running `serve claude`. Mirrors the 6 tools for the other direction.
- **Skill**: `dot_claude/skills/codex/SKILL.md` — `/codex` slash command that routes to the right bridge tool.
- **Agent**: `dot_claude/agents/codex-teammate.md` — spawnable agent for longer Codex collaboration.
- **Codex skill**: `dot_agents/skills/claude/SKILL.md` — `/claude` slash command for the Codex side.

Pinned at `@0.3.1` to avoid supply chain drift from `npx` fetching latest.

## 2026-04-24 — Drift triage: Zed, settings.local.json modify script, serena untrack, codex apply

### Problem

`chezmoi status` revealed 5 drifted files across the repo. Triaged each:

- **`.config/zed/settings.json`** — chezmoi source was already correct (theme object, Monaspace Neon font, `relative_line_numbers: true`). Zed had re-injected stale agent settings into the deployed file. Just needed `chezmoi apply --force`.
- **`.claude/settings.local.json`** — static source file caused constant drift because each machine accumulates different local permissions. Converted to a `modify_settings.local.json` script that merges a baseline permission set (`WebFetch(domain:ghostty.org)`) with existing machine-specific permissions.
- **`.codex/config.toml`** — modify script already had `model_reasoning_effort = "high"` but deployed file still had `"medium"`. Applied.
- **`.serena/serena_config.yml`** — upstream Serena rewrites this file on every launch (comment changes, removed `web_dashboard_interface` key). Not worth tracking. Untracked by deleting source file.
- **`.claude.json`** — modify script already strips `cachedExtraUsageDisabledReason` on apply. No source change needed.

### Fix

- Applied `~/.config/zed/settings.json` and `~/.codex/config.toml` (no 1Password needed).
- Replaced `dot_claude/settings.local.json` (static) → `dot_claude/modify_settings.local.json` (merge script). Base perms go first, then existing on-disk perms are unioned via `jq unique`.
- Deleted `dot_serena/serena_config.yml` source to untrack.

## 2026-04-14 — Work/personal split for Anthropic OAuth token

### Problem

Started a new job (`latios` is the work machine). The `CLAUDE_CODE_OAUTH_TOKEN` in `dot_zshenv.tmpl` was a single personal credential rendered on all machines.

### Fix

- Added `work = ["latios"]` to `[host_groups]` in `.chezmoidata.toml`
- Wrapped `CLAUDE_CODE_OAUTH_TOKEN` in `dot_zshenv.tmpl` with a host group conditional:
  - `work` machines → `op://focused/claude code oauth token/credential`
  - all other machines → existing personal path `op://Private/Anthropic/Saved on console.anthropic.com/token`

To add more work machines later: append the hostname to `work = [...]` in `.chezmoidata.toml`.

## 2026-04-12 — Untrack `opencode/package.json` and `picom` config

### Problem

Two sources were being managed by chezmoi but shouldn't be:

- `dot_config/opencode/package.json` — node package manifest tracked in chezmoi by accident; should live alongside the opencode install, not in dotfiles.
- `dot_config/symlink_picom` — a chezmoi-managed symlink pointing `~/.config/picom` → `../dotfiles/.config/picom`. No longer wanted.

### Fix

Removed both source files directly from `~/.local/share/chezmoi/`:

- `dot_config/opencode/package.json`
- `dot_config/symlink_picom`

(Equivalent to `chezmoi forget`, which couldn't be used here because it prompts interactively and the agent has no TTY.) Deleting the source untracks the target without touching the deployed files in `~/.config/`.
## 2026-04-08 — Resolve stash conflicts (zshenv, codex config)

### Problem

`git stash pop` conflicted with recent commits:
- `dot_zshenv.tmpl`: stash added `CLAUDE_CODE_OAUTH_TOKEN` and `OPENCLAW_DISCORD_READA`; HEAD added a `dev_infra` DB_URL block. Both modified.
- `dot_codex/private_config.toml.tmpl`: stash added `[features] multi_agent = true`, but HEAD had replaced the template with a `modify_private_config.toml` Python script (commit 9f5aed3).

### Fix

- `dot_zshenv.tmpl`: kept both changes — new env vars from stash plus the `dev_infra` conditional block from HEAD.
- Codex: accepted the template deletion, ported `features.multi_agent = True` into the new `modify_private_config.toml` BASE dict.
- Also includes `dot_chronicler.json.tmpl` update (paths moved from `.openclaw/workspace-navi` to `navi/` directory structure).

## 2026-04-08 — Track Claude plugin and MCP configs in chezmoi

### Problem

Serena MCP plugin was opening a browser window on every Claude Code startup (`web_dashboard_open_on_launch: true`). Fixed the setting, but the config at `~/.serena/serena_config.yml` wasn't tracked in chezmoi, nor were other Claude plugin/MCP configs.

### Fix

Added three new files to chezmoi:
- `dot_serena/serena_config.yml` — Serena plugin config (with `web_dashboard_open_on_launch: false`)
- `dot_config/mcp-config.json` — global MCP server registry (currently has open-websearch)
- `dot_claude/settings.local.json` — machine-specific Claude Code permission overrides

## 2026-04-04 — Ignore AI tool workspace dirs in .gitignore

### Problem

AI tools (Cursor, Codex CLI, Gemini CLI, Kilocode, OpenCode) create their own `.cursor/`, `.codex/`, `.gemini/`, `.kilocode/`, `.opencode/` directories when run inside the chezmoi source dir, polluting `git status`.

### Fix

Added the five directories to `.gitignore`. Follows the same pattern as `.claude/` which was already ignored. The chezmoi-managed `dot_codex/` (and `dot_claude/`) source dirs are unaffected.

## 2026-03-28 — Fix empty bash function bodies crashing chezmoi apply on macOS

### Problem
`chezmoi apply` failed on macOS with:
```
bash: line 32: syntax error near unexpected token `}'
```

The root cause: `install_linux_dependencies()` and `install_wsl_clipboard()` were defined unconditionally in `run_once_03_install-packages.sh.tmpl`, but their entire bodies were wrapped in `{{ if eq .chezmoi.os "linux" }}`. On macOS, the template rendered these as empty-body functions (just whitespace), which is invalid bash syntax.

Previous commits (c6bffbe, d8e65a6) had fixed a related issue — `.osRelease.id` being evaluated inside `and`/`or` function calls on macOS — but did not address the empty-body problem.

### Fix
Moved both Linux-only function definitions inside a top-level `{{ if eq .chezmoi.os "linux" }}` block in `run_once_03_install-packages.sh.tmpl`. The functions are only called on Linux (already guarded), so this is safe. The rendered bash on macOS no longer contains these functions at all.

## 2026-03-28 — Guard Cargo env sourcing in zshenv

### Problem
Shell startup emitted:
```
/Users/rai/.zshenv:.:55: no such file or directory: /Users/rai/.cargo/env
```
because `dot_zshenv.tmpl` always sourced `$HOME/.cargo/env`, even when Rust/Cargo was not installed yet.

### Fix
Wrapped the source line in a file-existence check in `dot_zshenv.tmpl`:
```
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
```
This keeps shell startup clean on machines where Cargo has not been initialized.
