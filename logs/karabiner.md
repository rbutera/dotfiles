# karabiner config changes log

## 2026-06-05 — Built-in MacBook F/J home-row shift

### Problem

Rai wanted the built-in MacBook keyboard to use home-row shift keys without
changing external keyboards such as the Dygma Defy and Dygma Raise.

### Changes

Added a built-in-keyboard-only complex modification in
`dot_config/private_karabiner/private_karabiner.json`:

- `f` sends `f` when tapped and `left_shift` when held
- `j` sends `j` when tapped and `right_shift` when held
- Both manipulators use `device_if` with `is_built_in_keyboard: true`, so the
  rule does not apply to external keyboards
- Initial timing: `120ms` hold threshold and `170ms` tap timeout, chosen as a
  fast-typing starting point for roughly 110wpm

## 2026-06-04 — Dygma Defy: leave caps lock as plain caps lock

### Problem

The `CAPS_LOCK -> Hyper/Escape Key` complex modification (caps lock → Escape on
tap, Hyper = cmd+ctrl+opt on hold) used a `device_unless` condition that excluded
only the **Dygma Raise** (`product_id 8705`, `vendor_id 4617`). As a result the
remap still fired on the **Dygma Defy** (`product_id 18`, `vendor_id 13807`),
turning its caps lock key into Escape/Hyper. User wanted caps lock to behave as a
plain caps lock on the Defy.

### Changes

Added the Dygma Defy identifier (`product_id 18`, `vendor_id 13807`) to the
`device_unless` identifiers array of the `CAPS_LOCK -> Hyper/Escape Key`
manipulator in `dot_config/private_karabiner/private_karabiner.json`. The caps
lock remap now applies on every device **except** the Dygma Raise and the Dygma
Defy. On the Defy, `caps_lock` passes through untouched.

The Defy's Hyper/Escape behaviour is unaffected — it comes from the separate
`(Dygma Defy) F14 / F19` rules, not from the caps lock key.

## 2026-04-15 — Dygma Defy F18: replace ctrl/ctrl+space with Hyper+Space

### Problem

The Dygma Defy F18 complex modification was mapped as ctrl-on-hold, ctrl+space-on-tap. User wanted F18 to produce Hyper+Space instead — a single unambiguous chord that tools like Raycast, Alfred, or custom Hammerspoon bindings can hook without clashing with plain `ctrl+space` (which IMEs, Spotlight, and many apps bind).

### Changes

Replaced the `(Dygma Defy) F18` manipulator in `dot_config/private_karabiner/private_karabiner.json`:

- **Before**: `to: left_control` + `to_if_alone: ctrl+space` (hold/tap split)
- **After**: `to: spacebar` with modifiers `[left_command, left_control, left_option]` — a straight Hyper+Space on key-down, no hold/tap split
- Description updated from `(Dygma Defy) F18 -> ctrl on hold, ctrl+space on tap` to `(Dygma Defy) F18 -> Hyper+Space`

Hyper = `cmd+ctrl+opt` matches the convention used elsewhere in this file (F14, F19, CAPS_LOCK mappings, and all "Hyper app switching" rules).

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
