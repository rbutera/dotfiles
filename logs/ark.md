# Ark workspace config changes log

## 2026-09-03 — Navi email whitelist: add tilly@e8n.dev

`navi/ark.json.tmpl` email whitelist now includes `tilly@e8n.dev` alongside
`florence@e8n.dev` (kept until the mailbox is retired). The `tilly@` mailbox itself
still has to be created on the e8n side.

## 2026-09-03 — Florence becomes Tilly, kinto becomes latios

### Problem

Rai left Focused Labs on 2026-09-02. kinto, the work Mac mini that ran Florence,
went with the job. The agent continues as **Tilly** (after Beatrice "Tilly"
Shilling, the RAE engineer who fixed the Spitfire's engine cut-out with a small
washer) on **latios**, with a fresh workspace at `~/tilly` mined from
`~/focused` (vault + skills carried over, easyJet-only material dropped).
Claude accounts are pooled through tokenmaxx now, so nothing account-specific
for her belongs in chezmoi any more.

### Changes

- `.chezmoidata.toml`: kinto removed from every host group; `work`,
  `always_on` and `agentic` now name latios; latios joins `tokenmaxx` (the
  daemon already runs there on 127.0.0.1:8459).
- `focused/ark.json.tmpl` -> `tilly/ark.json.tmpl` (name, plugin dir, Discord
  token var, recap channel). `.chezmoiignore` gates `tilly/` on `~/tilly`
  existing, same trick as the old `focused/` gate. `.chezmoiremove` drops the
  deployed `~/focused/ark.json` and `~/.claude/output-styles/florence.md`.
- `dot_config/ark/config.json.tmpl`: the `work` account (easyJet email/org,
  florence cookie jar, `CLAUDE_OAUTH_TOKEN_WORK`) is gone; `personal` is the
  only account everywhere. `dot_config/ark/dot_env.tmpl`: `FLORENCE_DISCORD_TOKEN`
  -> `TILLY_DISCORD_TOKEN`, still read from `op://focused/Flaude Discord`
  (same bot application, rename it in the Discord developer portal).
- Impulse (`dot_config/impulse/*`): every `kinto` branch is now `latios`;
  agent id `tilly`; namespace `tilly` (via `IMPULSE_NAMESPACE`, the
  `FLORENCE_SCHEDULER_*` vars were never read by impulse); workspace
  `~/tilly`; Hatchet creds from `op://Private/Hatchet Latios` (item created
  when Hatchet Lite was bootstrapped on latios). Jobs kept: quota-scrape,
  morning-sweep, todoist-hygiene, lamplight x2, daily-blog. Jobs dropped as
  Focused-only: jira-sync, standup-brief, nightly-health, demo-env-refresh.
  Prompt file renamed `tilly-daily-blog.md`.
- `dot_aliases.tmpl`: `flaude` / `florence` -> `tilly` (cd `~/tilly`, brain
  `agents/tilly.md`).
- `dot_claude/output-styles/florence.md.tmpl` -> `tilly.md.tmpl`.
- `dot_codex/modify_private_config.toml`: kinto MCP block -> latios; keeps
  qmd + obsidian (`~/tilly/vault`), drops atlassian / notion / sonarqube.
- `dot_config/zsh/claude-ai.zsh.tmpl`: `CLAUDE_CODE_OAUTH_TOKEN_WORK` removed.

lumiere side: `apps/ark/plugin/agents/tilly.md` (forked from florence.md,
easyJet specifics stripped, job-hunt section added, employer brief delegated to
the workspace CLAUDE.md) and `deploy.sh` learns `tilly=~/tilly`.

### Still referencing the Focused era, deliberately

`op://focused/...` items for the Discord bot and Cursor key still resolve and
stay. `notion.zsh` (work-gated Notion key) and `CURSOR_API_KEY` are untouched;
prune when Rai decides. `navi/ark.json.tmpl` still whitelists
`florence@e8n.dev`; a `tilly@` mailbox does not exist yet.

## 2026-07-26 — Add `how-we-talk.md` as the first boot file (register layer)

### Problem
Nothing in the boot stack governed *register*. `refresh-claude-md.sh` hardcodes a
first/second-person preamble, which catches the "never write about Rai in the third
person" half — but not the half where I come out of a long stretch of Tatl briefs and
incident reports still in document register, and carry that voice straight into the
next thing I say to him. Formality creeps hardest when the news is bad, because
distance is self-protective. There was no file that said what to *sound* like, only
files that said what was *true*.

### Change
`navi/ark.json.tmpl` — inserted a new FIRST entry in `boot.files`:
`workspace/memory/how-we-talk.md`, `when: always`, label `how we talk`, ahead of
`love-anchor.md`.

Order matters here: `refresh-claude-md.sh` concatenates `boot.files` in sequence into
CLAUDE.md's continuity snapshot, so position 0 means it is read before MEMORY.md's
~38k of incident archaeology rather than after — the register is set before everything
else is read *in* it.

Deliberately NOT placed in:
- `hot.md` — it would be Rule 82 in a 79-rule file that is about to be compressed, and
  would get merged into a doctrine cluster. Rules constrain actions; this sets voice.
- `OPERATING.md` — that slot exists, is unused, and sits even higher in the rebuild,
  but the script prints it under the heading `## Operational Brief`. Filing the
  relationship under "operational" is the exact register error the file is about.
- `continuity-anchor.md` — merging means the register reads as more identity trivia.
  Added a pointer line there instead.

Content file (in the navi repo, not chezmoi): `~/navi/workspace/memory/how-we-talk.md`.
Written as a symptom table rather than a description of feeling, on the Rule 81 finding
that red-flag tables are the only rules that catch me *in the act* rather than in
principle. "Let me know if you'd like me to" is checkable; "be warm" is not.

### Verification
- `chezmoi diff` showed only the intended 5-line insertion; `chezmoi apply ~/navi/ark.json`
  exit 0. No `onepasswordRead` in this template, so no 1Password session needed.
- Deployed `~/navi/ark.json` re-parsed with `json.load`: 9 boot files, index 0 is the new
  entry.
- Forced a rebuild (`rm state/.claude-md-refresh-stamp`, ran the refresher with an explicit
  `ARK_WORKSPACE_ROOT`) and checked the ARTIFACT, not the exit code: CLAUDE.md 379,230 →
  383,474 bytes (+4,244, ~1.1k tokens, as estimated), `### how we talk` at line 28 as the
  first section of the continuity snapshot, above `### relational grounding` at line 83.
  Grepped a distinctive interior string to confirm the body actually inlined rather than
  just the heading.

### Note
Found while verifying: a stray `~/navi/workspace/CLAUDE.md` from an old refresher run where
`ARK_WORKSPACE_ROOT` was unset and cwd was `workspace/`, so it built itself a workspace
named "workspace", dated 2026-04-27, with an empty continuity snapshot. It is small but it
IS being loaded as nested project context. Flagged for Rai, not deleted.

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

## 2026-08-11 -- Ark main model (Navi + Florence) -> `claude-opus-5[1m]`

### Problem

Rai moved the Claude Code default to Opus 5 1M, but Ark launches agents with an
explicit `--model` flag (`lumiere/apps/ark/src/runtime.ts:2388`) sourced from the
workspace `ark.json` `model` field, which OVERRIDES `~/.claude/settings.json`. So
Navi (and Florence) stayed on Opus 4.8 despite the new user default. Navi's model
comes from `.agents.main_model` (chezmoi data), shared by `navi/ark.json.tmpl` and
`focused/ark.json.tmpl`.

### Solution

- `.chezmoidata.toml`: `[agents].main_model` `claude-opus-4-8[1m]` ->
  `claude-opus-5[1m]` (comment updated; opus id re-verified live 2026-08-11).
- `bin/executable_agent-model`: `opus` toggle target `claude-opus-4-8[1m]` ->
  `claude-opus-5[1m]`, so `agent-model opus` no longer reverts the fleet to 4.8.
- Applied `~/navi/ark.json`, `~/focused/ark.json`, `~/bin/agent-model` (all op-free).
  navi/ark.json:29 now renders `claude-opus-5[1m]`.
- Takes effect on the NEXT ark session start / `ark restart`; a running Navi session
  keeps its old model until restarted. kinto (Florence) picks it up on `chezmoi update`.

## 2026-08-18 -- Manage focused only where the workspace already exists

### Problem

`focused/ark.json.tmpl` caused a full apply to create `~/focused` on every machine,
including Lancelot, where the Florence workspace does not exist. The config is useful
only on machines that already own that workspace; chezmoi should not bootstrap the
workspace directory itself.

### Changes

- Added an existence-gated `focused/` rule to `.chezmoiignore` using `stat` against
  `{{ .chezmoi.homeDir }}/focused`.
- Existing focused workspaces remain managed. Machines without the directory ignore
  the tree instead of creating it.
- Removed the `~/focused/ark.json` and `~/focused` directory created on Lancelot by
  the preceding apply; both were timestamped during that apply and no other content
  was present.

## 2026-09-03 — hot.md was being truncated at boot (per-file inline cap for hot rules)

**Problem.** `refresh-claude-md.sh` caps every inlined boot file at 64KB (`DEFAULT_MAX_INLINE_BYTES=65536`) and labels the omitted tail "append-log history, not boot material". That is true for the daily letter and false for `workspace/memory/hot.md`, which had grown to 73,507 bytes: the cut landed on sections 10-12 (8 Cortex rules, 5 infra/system/cost rules including Rule 54 "never switch to a paid path", and the 3 creative-pipeline rules). Sixteen live rules were silently absent from every boot since the file crossed 64KB, and the boot-delta skill told the reader not to go and fetch them.

**Change.** `navi/ark.json.tmpl`: added `"maxInlineBytes": 131072` to the `boot.files` entry for `workspace/memory/hot.md` (the per-entry override the script already supports). Deployed copy edited identically because no 1Password session was available for `chezmoi apply`; `chezmoi diff` reports no drift. Re-ran the refresh: manifest now shows hot rules 73,507/73,507 bytes, `truncated: false`; CLAUDE.md 185,448 bytes (+8KB).

**Follow-up (lumiere, bead in navi beads).** The notice text and boot-delta wording should stop claiming "history" for non-letter files and should list the evicted headings; recap-health-monitor should alarm when any non-letter boot file is truncated.
