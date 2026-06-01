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
