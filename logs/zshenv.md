# zshenv changelog

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
