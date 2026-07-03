# voice-goon changelog

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