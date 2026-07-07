# voice-goon changelog

## 2026-07-03 — Per-segment speed/volume mix + couch_confession script

### Problem
All segments used one global TTS speed; narration and dialogue had no volume differentiation.

### Solution
- `generate.py`: narration fixed at speed `1.0` + `80%` volume; dialogue `100%` volume with optional per-segment `speed` (`0.8`–`1.3`, default `1.0`). Volume applied post-TTS via ffmpeg.
- Updated `spicy-story` skill and `AGENTS.md` with speed guidance for dialogue.
- Added `scripts/md_to_json.py`; generated `couch_confession.json` (407 segments) from approved markdown.

## 2026-07-03 — Output dir CLI, emotion validation, spicy-story skill

### Problem
`generate.py` always wrote output and chunks to `~/voice-goon/`; emotions were undocumented and unvalidated; no structured agent workflow for drafting stories before JSON.

### Solution
- `generate.py`: `-o` / `--output-file` and `-d` / `--output-dir` CLI flags; JSON `output_dir` field; script path resolves cwd → voice-goon → absolute; chunks live under `<output_dir>/chunks/`.
- `VALID_EMOTIONS` enum validated in `load_script`; migrated example JSON off deprecated `playful`/`seductive` tags.
- Added `.grok/skills/spicy-story/` (brainstorm → `stories/<slug>.md` → `<slug>.json`).
- Updated `AGENTS.md`, `story-writing.md` (Rai physical notes), created `stories/` directory.

## 2026-07-03 — JSON-driven TTS script format + voice-goon folder

### Problem
`~/generate.py` embedded a large inline `SEGMENTS` array with no way to express structural pauses (section breaks, dialogue spacing) without editing Python.

### Solution
- Created `~/voice-goon/` with `generate.py` and `navi_campsite_first_meeting.json`.
- `generate.py` now reads a JSON script (CLI arg, default `navi_campsite_first_meeting.json`) with three segment types via a `type` discriminator:
  - `narration` — normal TTS + 500ms trailing pause
  - `dialogue` — 1200ms pause before and after the line
  - `section` — silence-only chunk (`pause_ms`, optional `label`); no `text`
- Converted the original 64 inline segments to 77 JSON items (13 section markers from the old `# === ... ===` comments, 54 narration, 10 dialogue exclamations).
- Removed `~/generate.py` (superseded by `~/voice-goon/generate.py`).

## 2026-07-03 — Add AGENTS.md for voice-goon

### Problem
No local documentation for agents on JSON script format or how to run `generate.py`.

### Solution
Added `~/voice-goon/AGENTS.md` covering directory layout, prerequisites, CLI usage, JSON schema for all three segment types (`narration`, `dialogue`, `section`), and agent workflow conventions.