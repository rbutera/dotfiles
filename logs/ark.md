# Ark workspace config changes log

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
