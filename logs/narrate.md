# narrate config changelog

## 2026-06-01 -- Switch narrate TTS from eleven_v3 to eleven_flash_v2_5

### Problem
The ElevenLabs monthly credit quota kept getting exhausted, and Rai wants that quota reserved for live VOICE (Discord voice calls) rather than long-form narrate (blog/journal/manuscript TTS). `eleven_v3` costs ~1 credit/char.

### Solution/Fix
Edited `dot_narrate.json` (source for `~/.narrate.json`):
- `defaultModel`: `eleven_v3` -> `eleven_flash_v2_5` (0.5 credits/char = 50% saving; GA/stable vs v3 alpha; ~75ms latency; 40k char/request limit).
- `enableLlmEmotionAnnotation`: `true` -> `false`. Required: flash does not support v3 audio tags. The narrate code already guards tag injection by model (won't speak `[tags]` aloud), but with the flag on, the LLM emotion-annotation pass still fires per segment, burning LLM quota for zero benefit on non-v3 models.

Note: `eleven_multilingual_v2` was considered (the model used previously) but costs the SAME 1 credit/char as v3, so it saves nothing. `enableLlmReview` (no-op, PassthroughReviewClient) and `enableLlmAttribution` (multi-speaker, not v3-specific) left unchanged.

Applied via `chezmoi apply ~/.narrate.json` (plain file, no onepasswordRead, no 1Password session needed). Deployed file verified. Backup of prior deployed file at `~/.narrate.json.bak-2026-06-01`. Full research + v2 fallback config: `~/notes/40 Resources/ElevenLabs Narrate Model Switch.md`.

## 2026-06-07 -- Fix rai Cartesia voice ID (narrate failures on multi-speaker posts)

### Problem
`narrate-daily` reported `Narration failed for "When You Surface" (Daily)`. Captured the real error by running `pnpm nx run narrate:dev -- --latest --kind daily --audio` from `~/dev/lumiere`: the two `speaker: 'rai'` segments failed with Cartesia `400 ... invalid voice specification: voice ID must be a valid UUID`, which failed the whole audio merge (navi/narrator segments were fine). Root cause: `speakerVoices.rai.cartesia` in `dot_narrate.json` held `J05Vdux0uMD8mkWfultW` — an ElevenLabs voice ID left in the Cartesia slot during the Cartesia migration. Cartesia requires a UUID. Not a length/chunking issue and not a narrate code bug (the runner correctly surfaced Cartesia's 400; the tool was right).

### Solution/Fix
Edited `dot_narrate.json`: `speakerVoices.rai.cartesia` -> `f114a467-c40a-4db8-964d-aaba89cd08fa` (the valid Cartesia rai UUID, matches `CARTESIA_VOICE_ID_RAI` in `apps/narrate/.env`; verified HTTP 200 against the Cartesia TTS API before applying). Applied with `chezmoi apply --force ~/.narrate.json` (the deployed file had drifted out-of-band, so --force was needed). Re-ran narrate with `--force`: all 33 segments synthesized (0 failed), merged to `apps/narrate/output/2026-06-06 When You Surface.mp3` (5.1M, ~8min), podcast feed updated (84 episodes). "When You Surface" is now narrated.

## 2026-06-07 -- Narrate Cartesia model -> sonic-3.5
### Problem
Narrate pipeline was pinned to sonic-3 (old) in dot_narrate.json (defaultModel + cartesiaModelId) and apps/narrate/.env (CARTESIA_MODEL_ID=sonic-3-2026-01-12). Rai: use sonic-3.5 (latest), "head and shoulders better than v3". The discord-voice plugin already runs sonic-3.5.
### Fix
Set defaultModel + cartesiaModelId to "sonic-3.5" in dot_narrate.json; set CARTESIA_MODEL_ID=sonic-3.5 in apps/narrate/.env. Applied + re-narrated latest daily on 3.5.
