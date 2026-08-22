# chezmoi modify scripts changelog

## 2026-08-10 — `dot_claude/modify_settings.json`: stop deleting `env`, pin `ENABLE_TOOL_SEARCH=true`

### Problem
Every Claude Code session was loading ~400 MCP tool schemas (~100K tokens) into
context up front. Tool Search (deferred tool loading) is default-on in Claude
Code ≥2.1.121, but it **auto-disables when `ANTHROPIC_BASE_URL` points at a
proxy** — and the whole fleet routes through the tokenmaxx quota proxy on
127.0.0.1:8459. Verified empirically 2026-08-10: a session with
`ENABLE_TOOL_SEARCH=true` through tokenmaxx comes up with ~11 resident tools and
200+ deferred, no API errors.

Separately, the modify script ran `del(.env)` wholesale on every apply, which
would have wiped both the fix AND `ANTHROPIC_BASE_URL` itself (silently
bypassing the tokenmaxx proxy on the next `chezmoi apply`).

### Change
`del(.env)` replaced with: keep only the machine-local `ANTHROPIC_BASE_URL`
(if present), then merge `{"ENABLE_TOOL_SEARCH": "true"}`. Other stale env keys
are still dropped, preserving the old cleanup intent. Header comment documents
the reasoning. Pipe-tested: current deployed settings round-trip with env
`{ANTHROPIC_BASE_URL, ENABLE_TOOL_SEARCH}`, model and hooks intact.

## 2026-07-23 — New `dot_omp/agent/modify_config.yml` (omp provider pruning, fleet-wide)

### Problem
`omp` auto-enables a provider the moment it finds a credential, and the
credential often arrives from somewhere unintended — OpenRouter from a stray key
in `~/.env`, AWS Bedrock from the easyJet `AWS_PROFILE`. The model picker hit
**611 models across 7 providers**. `disabledProviders` is the only setting that
hides a provider outright (picker, `/login`, and background discovery probes),
but it lives in `~/.omp/agent/config.yml`, which omp owns and rewrites at
runtime. Setting it with `omp config set` fixed kinto and left nimbus/latios
noisy. See logs/pi.md for the provider-by-provider rationale.

### Solution
New **plain-python** modify script (no `.tmpl` — no 1Password, no host
branching) owning exactly one key, `disabledProviders`; everything else
(`setupVersion`, `modelRoles`, `theme`, `task`, and any key a future omp release
adds) passes through byte-for-byte.

**Text-surgical, deliberately NOT a YAML round-trip.** omp writes a dialect with
a trailing space after every block-opening key (`disabledProviders: `) and **no
trailing newline at EOF**. pyyaml or `yq` would reformat the whole file and leave
chezmoi reporting permanent drift against omp's own writes — the same class as
the jq trailing-newline drift fixed in `modify_dot_claude.json.tmpl` on
2026-07-14. The script reproduces omp's bytes exactly instead.

The key is replaced **in place** when present, so it keeps whatever position omp
last gave it and the diff stays minimal; appended at EOF only when absent.

### Verification
Seven cases, all passing:
1. current file → **byte-identical** output (`cmp` clean, so no drift loop)
2. empty stdin (fresh machine) → managed block only
3. key absent → appended, omp's keys preserved
4. key mid-file with stale values → replaced in place, following keys preserved
5. inline flow style (`disabledProviders: ["openrouter","groq"]`) → normalised
6. input with a trailing newline → stripped to match omp
7. every output parses as valid YAML (`yaml.safe_load`)

End-to-end: hand-drifted the deployed file to `disabledProviders: [openrouter]`
plus an unrelated `someNewOmpSetting: 42`; `chezmoi status` → `MM`;
`chezmoi apply` restored the managed list **and kept `someNewOmpSetting`**.
`chezmoi status` clean afterwards, `omp config get disabledProviders` reads it
back correctly.

### Gotcha
The source file needs the executable bit (`chmod +x`) like every other
`modify_` script — it is not set by `Write`/`cp`.

## 2026-07-14 — Remove chisel MCP from claude + codex (pi inherits via discovery)

### Change
Rai retired the `chisel` MCP server. Removed its definition from both harness
modify scripts:
- `modify_dot_claude.json.tmpl` — dropped the `chisel` block from `base_mcps`.
- `dot_codex/modify_private_config.toml` — dropped `chisel` from
  `BASE["mcp_servers"]` and from the Windows `pop()` list (now
  `("tempograph", "oss-autopilot")`), since a server that no longer exists in
  BASE needn't be popped.

### Pi (Oh My Pi) has no dedicated MCP config
There is **no** pi-native MCP file (no `~/.omp/agent/mcp.json`, no
`~/.pi/agent/mcp.json`, nothing under `dot_pi/` beyond auth). Per omp mcp-config
docs, pi *discovers* MCP servers from other tools' configs — chiefly the Claude
global config (`~/.claude.json` `mcpServers`) plus opencode/etc. So removing
chisel from the claude modify script IS the removal for pi; no separate pi edit
exists. (chisel was defined only in claude + codex; opencode configs never had
it.) Applied to live claude.json (already chisel-free) and `~/.codex/config.toml`.

## 2026-07-14 — jq trailing-newline drift (claude.json) + new npmrc modify script

### Problem 1: `modify_dot_claude.json.tmpl` drifted every session
The script ended with a bare `jq` pipeline. `jq` always appends a trailing
newline, but Claude Code rewrites `~/.claude.json` with **no** trailing newline.
So `chezmoi status` reported the file `MM` after every session over a 1-byte
diff that could never be resolved by a normal sync.

### Fix 1
Capture and re-emit without the newline:
```bash
result=$(echo "$current" | jq --argjson base "$base_mcps" … '…')
printf '%s' "$result"
```
`$(…)` strips trailing newlines; `printf '%s'` adds none → output byte-identical
to Claude's own writes. **Lesson: any modify script whose downstream consumer
writes without a trailing newline must strip jq's.**

### Problem 2: `.npmrc` auth token drift
`private_dot_npmrc.tmpl` templated the registry token from 1Password. A local
`npm login` rotated it; 1Password lagged → permanent drift, and `apply` would
revert to the stale token.

### Fix 2: `modify_private_dot_npmrc` (new)
Plain-bash modify script (no `.tmpl` — no 1Password). Emits the managed
supply-chain directive block, then preserves registry-scoped lines verbatim:
```bash
printf '%s\n' "$current" | grep -E '^//' || true
```
Config knobs are chezmoi-owned; the auth token is owned by `npm login` and never
touched. **Lesson: for files where a secret sub-line is written by an external
tool (npm login, gh auth), a modify script that manages the rest and passes the
secret line through beats templating the secret from 1Password.** (See npm.md.)

## 2026-05-15 — Exclude chisel, tempograph, oss-autopilot on Windows

### Problem
Three MCP servers fail on Windows:
- **chisel** — Unix-only Rust binary (POSIX syscalls, Unix shell whitelist). Not installable on Windows.
- **tempograph** — Python dependency `py-rust-stemmers` fails to compile on Windows (needs maturin + Rust build chain).
- **oss-autopilot** — fails to connect on Windows.

### Changes
- **`run_onchange_apply-claude-json-windows.ps1`**: Removed chisel, tempograph, and oss-autopilot from `$baseMcpsJson`. They remain in the bash `modify_dot_claude.json.tmpl` for Linux/macOS.
- **`dot_codex/modify_private_config.toml`**: Added `sys.platform == "win32"` guard that pops the three servers from `BASE["mcp_servers"]` on Windows.

## 2026-04-10 — Force open-websearch to stdio-only in Codex

### Problem

`open-websearch` defaults to `MODE=both`, which starts MCP stdio and also an HTTP server on port `3000`.
When another process already owns `3000`, startup crashes with `EADDRINUSE` after stdio connects, and Codex reports a closed connection during MCP initialize.

### Changes

- `dot_codex/modify_private_config.toml`: added `env.MODE = "stdio"` for the `open-websearch` MCP entry so Codex launches it without the extra HTTP listener

## 2026-04-10 — Fix tempograph entrypoint, remove mcp-alchemy from Claude config

### Problem
Three MCP servers were failing with `-32000: connection closed` in Claude Code (and opencode):
- **tempograph** — wrong entrypoint `tempograph` (CLI, requires `repo` arg) instead of `tempograph-server` (MCP stdio server). Same bug was already fixed in the codex config on 2026-04-08 but never applied to the claude config.
- **mcp-alchemy** — no `DB_URL` env var set, so it starts and immediately exits. Already removed from codex for the same reason.
- **open-websearch** — was actually working fine, likely a transient npx issue.

### Changes
- `modify_dot_claude.json.tmpl`: changed tempograph args from `["--from", "tempograph[full]", "tempograph"]` to `["--from", "tempograph[full]", "tempograph-server"]`
- `modify_dot_claude.json.tmpl`: removed `mcp-alchemy` entry entirely (no database to connect to)

## 2026-04-08 -- Make MCP server lists authoritative (replace, not merge)

### Problem
The modify scripts for both Claude Code and Codex used additive merge for MCP servers. Removing an MCP server from the chezmoi source had no effect on the deployed config because the old key survived the merge. Stale entries like `mcp-redis` and `url` fields persisted forever.

### Solution/Fix
- **Claude Code** (`modify_dot_claude.json.tmpl`): changed jq from `'.mcpServers = ((.mcpServers // {}) * $base)'` to `'.mcpServers = $base'`. Base is now the sole source of truth for MCP servers.
- **Codex CLI** (`dot_codex/modify_private_config.toml`): after the deep_merge, override `mcp_servers`, `model_providers`, and `plugins` keys entirely from BASE. Free keys (`projects`, `notice`) still survive the merge as before.

This means: add an MCP server to chezmoi source, it appears. Remove it, it disappears. No more stale ghosts.

## 2026-04-08 -- Fix tomllib import on macOS (Python 3.9) in Codex modify script

### Problem
`dot_codex/modify_private_config.toml` imports `tomllib` which requires Python 3.11+. macOS system Python is 3.9.6, so `chezmoi apply` fails with `ModuleNotFoundError: No module named 'tomllib'`.

### Solution/Fix
Added try/except fallback chain: try `tomllib` (3.11+) first, then `tomli` backport, then fail with a clear error message. Installed `tomli` and `tomli-w` via pip for macOS system Python (`/usr/bin/python3 -m pip install tomli tomli-w`). On Arch this was fine because `python-tomli-w` package was already installed and Python is 3.12+.

## 2026-04-08 -- Fix osRelease crashes on macOS across multiple templates

### Problem
Several templates accessed `.chezmoi.osRelease.id` or `.chezmoi.osRelease.idLike` without first checking if `.chezmoi.os == "linux"`. On macOS, `.chezmoi.osRelease` doesn't exist at all (it's a Linux-only map), causing `chezmoi apply` to fail with: `map has no entry for key "id"`.

### Solution/Fix
Added `eq .chezmoi.os "linux"` as the outer guard in `and` chains before any `.chezmoi.osRelease` access. Go templates short-circuit `and`, so the `osRelease` access is never evaluated on macOS.

Files fixed:
- `modify_dot_claude.json.tmpl:58` (arch-linux MCP server block)
- `dot_config/ghostty/config.tmpl:12` (GeistMono font on Arch)
- `dot_aliases.tmpl:196` (BALDING_GATE_DIR on Arch)

Files already safe (already inside `{{ if eq .chezmoi.os "linux" }}` blocks):
- `dot_aliases.tmpl:227`, `dot_zprofile.tmpl:132`

Files not fixed (run_once scripts are broken/ignored anyway):
- `run_once_01`, `run_once_03`, `run_once_03b` (all already gated or never run on macOS)

## 2026-04-08 — Add Tier 1 MCP servers + Chisel to modify scripts

### Changes
Added the following MCP servers to both `modify_dot_claude.json` and `dot_codex/modify_private_config.toml`:
- **mcp-alchemy** — SQLAlchemy-based multi-DB (Postgres, MySQL, SQLite). Needs `DB_URL` env var.
- **mcp-redis** — Official Redis MCP. Defaults to localhost:6379.
- **tempograph** — Code graph context engine, 24 tools, tree-sitter for 170+ languages. No API keys.
- **oss-autopilot** — Open source contribution manager, PR tracking, CI diagnosis. Uses `gh` auth.
- **pty-mcp** — Persistent PTY/SSH sessions. Single Go binary installed to ~/bin.
- **chisel** — File ops with 20-100x token savings via diffs. Rust binary in ~/bin, `--stdio` mode (no HTTP/auth).
- **better-notion-mcp** — Notion integration with 77% token reduction. Needs `NOTION_TOKEN`.

Also updated `dot_claude/modify_settings.json` with newly enabled plugins (superpowers, skill-creator, claude-md-management, commit-commands, serena, plugin-dev, slack, chrome-devtools-mcp, mcp-server-dev).

### Binaries installed
- `~/bin/pty-mcp` + `~/bin/ai-tmux` (from pty-mcp installer)
- `~/bin/chisel` (from GitHub releases, linux-x86_64)

## 2026-04-08 — Add modify script for ~/.claude.json (global MCP servers)

### Problem
Claude Code stores global MCP servers in `~/.claude.json`, not `~/.claude/settings.json`. The `add-mcp` tool writes to this file, but it also contains runtime state (numStartups, tipsHistory, etc.) that shouldn't be tracked.

### Changes
- Created `modify_dot_claude.json` — shell script using `jq` to merge managed `mcpServers` into `~/.claude.json`
- Managed fields: `mcpServers` only
- Free fields: everything else (runtime state)
- Also updated `dot_codex/modify_private_config.toml` to include `command`/`args` for open-websearch (was missing, only had `url`)
- Updated `docs/mcp.md` to document the new modify script

## 2026-04-08 — Convert Claude Code and Codex CLI configs to modify scripts

### Problem
Static chezmoi-managed config files for Claude Code (`dot_claude/settings.json`) and Codex CLI (`dot_codex/private_config.toml.tmpl`) were always out of sync with the live configs on the system. Both tools modify their own config files at runtime — Claude Code adds per-project permissions, Codex adds trusted projects and migration notices. Every `chezmoi apply` would overwrite these runtime additions.

### Solution
Replaced static config files with chezmoi `modify_` scripts. These scripts receive the current file contents on stdin, merge in managed base config, and output the result — preserving app-managed fields while ensuring base config is consistent across machines.

### Changes

**Claude Code** (`dot_claude/modify_settings.json`):
- Shell script using `jq` for JSON merging
- Managed fields: `cleanupPeriodDays`, `enabledPlugins`
- Free fields (preserved): `permissions`, `model`, `attribution`, `skipDangerousModePermissionPrompt`, and anything else the app adds
- `enabledPlugins` merge is additive — base plugins always present, per-machine extras preserved

**Codex CLI** (`dot_codex/modify_private_config.toml`):
- Python script using `tomllib` (read) + `tomli_w` (write) for lossless TOML round-tripping
- Uses `/usr/bin/python3` shebang (not `/usr/bin/env python3`) because asdf's Python shim doesn't see system site-packages where `tomli_w` is installed
- Managed fields: top-level settings, `sandbox`, `mcp_servers`, `model_providers`, `plugins`
- Free fields (preserved): `projects` (machine-specific trusted paths), `notice` (app-managed migration state)
- Deep merge: base config wins for managed keys, existing config adds free keys

### Removed
- `dot_claude/settings.json` (replaced by modify script)
- `dot_codex/private_config.toml.tmpl` (replaced by modify script)

### Dependencies
- `jq` (for Claude Code modify script)
- `python-tomli-w` system package (for Codex modify script) — installed via `paru -S python-tomli-w`

### Notes
- Both scripts are idempotent — running `chezmoi apply` multiple times produces no diff
- To add a new MCP server to Codex across all machines, add it to the `BASE` dict in the modify script
- To add a new Claude Code plugin across all machines, add it to the `base` JSON in the modify script
- `yq` was evaluated for TOML but rejected — it strips quotes from keys and reformats arrays, breaking Codex's expected format

## 2026-08-22 — Uninstall `superpowers` plugin across all harnesses

**Why:** `superpowers` (Anthropic marketplace plugin + community marketplace) was
still activating everywhere — including ChatGPT/Codex desktop on Windows, where a
trusted `session_start` hook kept injecting the "using-superpowers" preamble. Rai
wanted it completely uninstalled from every harness and machine, permanently.

**What changed (both modify scripts made self-healing):**

- `dot_claude/modify_settings.json`: removed `superpowers@claude-plugins-official`
  from the managed `enabledPlugins` base, AND added it to the `del(...)` strip-list
  (same pattern as slack/discord/context7/codex) so it's actively removed from any
  deployed `settings.json` on every apply — the additive merge would otherwise
  preserve an existing `superpowers: true`.
- `dot_codex/modify_private_config.toml`: added `_prune_superpowers(merged)`. The
  `plugins`-are-authoritative rule already dropped the plugin entry, but the
  desktop app also writes a **`[hooks.state."superpowers@...:session_start"]`**
  trusted-hook entry under `hooks`, which `deep_merge` preserves. The prune strips
  any `superpowers` key from `plugins`, `marketplaces`, and `hooks.state`, so a
  re-add by the app cannot survive a `chezmoi apply`.
- Cleaned dangling references in `dot_claude/skills/wave/SKILL.md` (plan-file path)
  and `dot_omp/agent/skills/interaction-test-plan/SKILL.md` (parallel-dispatch note).

**Local teardown (this machine, WSL + Windows):** removed the Claude plugin dirs
(`~/.claude/plugins/{data,marketplaces,cache}/…superpowers…`), stripped the two
Codex `config.toml` blocks on Windows, deleted the Codex plugin files
(`~/.codex/.tmp/plugins/plugins/superpowers`, `~/.codex/plugins/cache/claude-plugins-official/superpowers`),
and removed the stale `opencode.json.pre-superpowers-disable.bak`.

**Note:** chezmoi does not manage the plugin *cache* dirs, so other machines keep
their leftover cache files until manually deleted — but the plugin is disabled and
the hook stripped on their next apply, so it no longer activates.
