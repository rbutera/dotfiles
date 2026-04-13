# karabiner config changes log

## 2026-04-13 — Dygma Defy F14: add escape on tap

### Problem

The Dygma Defy F14 rule was mapped as hold-only (Hyper = ctrl+alt+cmd) with no
tap behavior — description read "No Escape". Tapping F14 on the Defy had no
effect, unlike the Dygma Raise which already had escape on tap.

### Solution

Updated the `(Dygma Defy) F14` manipulator in
`dot_config/private_karabiner/private_karabiner.json` to match the Raise rule:

- Added `"to_if_alone": [{ "key_code": "escape" }]`
- Updated description from "(Dygma Defy) F14 -> Hyper (No Escape)" to
  "(Dygma Defy) F14 -> Hyper/Escape Key"

Hold behavior (ctrl+alt+cmd / Hyper) is unchanged.
