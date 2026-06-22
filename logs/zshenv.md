# zshenv changelog

## 2026-06-22 — Drop Supermemory block from ai-apis group (apply failure)

### Motivation
After the 2026-06-21 split, `chezmoi apply` failed rendering
`dot_config/zsh/ai-apis.zsh.tmpl:15` with
`map has no entry for key "claude"`. The refactor had collapsed the three
pre-existing `SUPERMEMORY_*` exports (originally three separate
`onepasswordRead "op://Private/supermemory api key/<field>"` calls) into one
cached `onepasswordDetailsFields "supermemory api key" "Private"` read, then
indexed it as `$supermem.claude` / `.opencode` / `.credential`. The
`onepasswordDetailsFields` map keys don't match those field references, so the
`.claude` lookup returned no entry and aborted the whole apply. Rai confirmed he
doesn't use supermemory, so the block is removed entirely rather than re-mapped.

### What changed
- **`dot_config/zsh/ai-apis.zsh.tmpl`**: Removed the Supermemory block
  (`$supermem` assignment + `SUPERMEMORY_CC_API_KEY`, `SUPERMEMORY_API_KEY`,
  `SUPERMEMORY_OPENCLAW_API_KEY` exports).

## 2026-06-21 — Split secrets into sourced group files (Dotfiles Phase 1, focused-nswr)

### Motivation
`dot_zshenv.tmpl` carried ~70 inline `onepasswordRead` calls in one block, so every
`chezmoi apply` did ~70 sequential `op read` round-trips — the real source of the
"applying the env takes forever" pain (profiling showed shell startup itself is
already ~0ms; see `vault/research/dotfiles/phase1-zshenv-profiling.md`). Two wins:
(1) per-file apply — `chezmoi apply ~/.config/zsh/<group>.zsh` renders only that
group, so editing one key re-reads only that group's items, not all 70; (2)
whole-item caching — multi-field / duplicate items now fetched ONCE via
`onepasswordDetailsFields` instead of once per field.

### What changed
- **`dot_zshenv.tmpl`**: removed the whole inline `# Secrets (1Password)` block
  and replaced it with a loader that sources every `~/.config/zsh/*.zsh` (zsh
  `(N)` null-glob so an empty dir is a no-op). The structural `.zshenv` now has
  ZERO `onepasswordRead` calls → `chezmoi apply ~/.zshenv` never invokes 1Password.
- **`dot_config/zsh/*.zsh.tmpl`** (8 new group files): secrets carved out by
  domain — `claude-ai`, `github`, `ai-apis`, `easyjet` (whole file work-host
  gated), `discord`, `voice-media`, `tools`, `jobsearch`, plus `host-infra`
  (DB_URL dev_infra / DATABASE_URL nimbus). Every env var name + `op://` ref
  preserved exactly (verified: zero vars added/dropped vs the old block).
  Caching collapses: Navi Discord 14→1, EasyJet JIRA 9→1, github PAT 3→1,
  Supermemory 3→1, Elevenlabs 3→1, RunPod 3→1, Tailscale 2→1, Adzuna 2→1,
  OpenCode Zen 2→1, Expedition email 2→1. `| quote` added to all secret values.

### Behaviour preserved
Host conditionals kept; `CONFLUENCE_URL` still gets `/wiki` (now via
`printf "%s/wiki"` inside the quote). On non-work hosts the easyjet group renders
to its header comment only (zero op reads).

### Verify on apply (needs an unlocked 1Password session)
1. `op signin` / biometric unlock FIRST (the group files call `op read`).
2. `chezmoi apply ~/.zshenv` (instant, no op), then `chezmoi apply ~/.config/zsh`.
3. New shell: spot-check collapsed items, e.g. `${GITHUB_TOKEN:+SET}`,
   `${ATLASSIAN_API_KEY:+SET}`, `${OPENCLAW_DISCORD_ORCA:+SET}`, must print `SET`.
4. Run on BOTH kinto (work) and nimbus (personal) — host-gated blocks differ.

### Caveat
`onepasswordDetailsFields` keys by 1Password FIELD ID. Field ids here were taken
verbatim from the old `op://item/<field>` refs Rai already used. If any field's id
differs from its label in 1Password, that one var renders empty — the `:+SET`
spot-check catches it. No live verification was possible (no op session at refactor).

## 2026-06-19 -- Remove OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS (omo flakiness)

### Change
Removed `export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=1` (a leftover from the
oh-my-opencode-slim era). oh-my-openagent's background/parallel subagent delegation
reports completion unreliably — `call_omo_agent` can time out after the subagent
already shows completed, and fast-finishing tasks hang in "running" forever
(oh-my-openagent issues #3774, #4570, #1517). Unsetting the flag forces
foreground/synchronous delegation, which avoids the completion-handshake race.
Requires `chezmoi apply ~/.zshenv` (1Password) + a fresh shell + restart of any
running `openagent` session.

## 2026-06-19 -- Add CURSOR_API_KEY for the opencode `openagent` profile

### Change
Added `export CURSOR_API_KEY={{ "{{" }} onepasswordRead "op://focused/cursor API key/credential" {{ "}}" }}`
under the OpenCode section. Used by the `opencode-cursor` plugin in the `openagent`
profile to route the Sisyphus orchestrator (and oracle/vision) through the user's
Cursor Pro subscription (`cursor-acp/*` models). Requires `chezmoi apply` with an
active 1Password session. See `logs/opencode.md` and `docs/opencode-profiles.md`.

## 2026-06-05 -- Use normal Claude Opus 4.8 context window

### Problem
Work-host `.zshenv` exported `ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-8[1m]'`,
which made Claude Code default to the 1M context variant.

### Solution/Fix
Changed the work-host branch in `dot_zshenv.tmpl` to export
`ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-8'`, matching the existing
non-work branch and using the normal context window. Rai will run `chezmoi apply`.

## 2026-06-04 -- Add OpenAI + Ideogram image-gen API keys

### Problem
The creative pipeline (fanart, campfire wallpaper pu5x, anime stills) silently
depended on the flaky ChatGPT-via-browser adapter (bead workspace-xho3). The
deterministic fix is the direct image-gen APIs (pod-factory + the new
`~/navi/bin/gen-image.mjs`), but OPENAI_API_KEY and IDEOGRAM_API_KEY were never
exported anywhere — absent from env and from chezmoi source.

### Solution/Fix
Added two `onepasswordRead` exports to `dot_zshenv.tmpl` under a new "Image
generation" block (right after the Cartesia key): OPENAI_API_KEY from
`op://Private/OpenAI API/credential` and IDEOGRAM_API_KEY from
`op://Private/Ideogram API/credential` (canonical paths per pod-factory setup
docs). After `chezmoi apply` with a 1Password session, both keys are live and
`gen-image.mjs` / pod-factory work browser-free.

## 2026-06-01 -- Add GELATO_API_KEY for Dopamade Etsy fulfilment

### Problem
Rai created a Gelato print-on-demand shop and linked it to his Etsy (Dopamade). The Gelato API credential needs to be available in the shell environment for the automated fulfilment pipeline (programmatic product creation / order handling).

### Solution/Fix
Added to `dot_zshenv.tmpl` after the Civitai key:
`export GELATO_API_KEY={{ onepasswordRead "op://Private/Gelato/credential" }}`
1Password item: op://Private/Gelato/credential (Rai created it). Requires a 1Password session for `chezmoi apply` (zshenv is full of onepasswordRead). Rai applies.

## 2026-06-03 -- add CARTESIA_API_KEY

- Added `export CARTESIA_API_KEY={{ onepasswordRead "op://Private/Cartesia/credential" }}` to the API-keys block, for the Discord voice plugin's Cartesia migration (ElevenLabs -> Cartesia).
- op reference only (resolved at apply-time); no raw key in git.
- Lands in the shell env on next `chezmoi apply`. (The voice daemon reads the key from its own plugin .env, not the shell -- this is for shell/general use.)

## 2026-06-04 -- Remove IDEOGRAM_API_KEY, demote OPENAI_API_KEY to billing-only

### Problem
Image generation was migrated to a first-party Codex/ChatGPT-subscription path (lumiere `openai-json` `generateImage` + pod-factory + `~/navi/bin/gen-image.mjs`), killing the paid Ideogram + OpenAI-paid-API image paths (bead workspace-0vuc). The `IDEOGRAM_API_KEY` export was now unused anywhere.

### Solution/Fix
Removed the `IDEOGRAM_API_KEY` export from `dot_zshenv.tmpl` (added earlier the same day, now dead). Kept `OPENAI_API_KEY` (still read by `~/navi/bin/cost-report.mjs` for billing checks) and updated its comment to note image-gen has moved to the free codex path. Removal takes effect on next `chezmoi apply`; the lingering deployed export is harmless until then.

## 2026-06-07 — Dedupe CARTESIA_API_KEY

### Problem
`CARTESIA_API_KEY` appeared twice in `dot_zshenv.tmpl` (line ~141 in the API-key cluster + line ~184 under the "voice migration 2026-06-03" comment), with inconsistent spacing before `}}`. Rai noticed the key seemed missing from his deployed `~/.zshenv` and asked about it.

### Root cause
The deployed `~/.zshenv` lacks the key because `chezmoi apply` hasn't run since it was added to the template on 2026-06-03 (apply needs an active 1Password session for the `onepasswordRead`, which agents can't provide). The key works at runtime anyway because it's also present in the gitignored runtime `.env` files (navi, discord-voice-plugin, narrate).

### Fix
Removed the duplicate, kept the single documented line (`export CARTESIA_API_KEY={{ onepasswordRead "op://Private/Cartesia/credential" }}`) under the voice-migration comment, normalized spacing. Source-only change; no apply run. Rai still needs to `chezmoi apply` (after `op signin`) to get the key into his live shell env.
