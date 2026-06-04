# zshenv changelog

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
