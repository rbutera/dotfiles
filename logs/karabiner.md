# karabiner config changes log

## 2026-04-13 — Hyper app-switching shortcuts

### Problem

No global shortcuts for quickly switching to or launching frequently-used apps.

### Solution

Added a new "Hyper app switching" complex modification rule with 8 manipulators
in `dot_config/private_karabiner/private_karabiner.json`:

| Shortcut | Action |
|---|---|
| Hyper+B | Switch/launch Vivaldi |
| Hyper+Shift+B | New Vivaldi window (or launch) |
| Hyper+Enter | Switch/launch Ghostty |
| Hyper+` | New Ghostty window |
| Hyper+D | Switch/launch Vesktop |
| Hyper+O | Switch/launch Finder |
| Hyper+C | Switch/launch VS Code |
| Hyper+N | Switch/launch Obsidian |

Uses `open -a` (switch/launch) and `open -na` (new window) shell commands.
Finder uses an extra `osascript` call to ensure it activates properly.

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
