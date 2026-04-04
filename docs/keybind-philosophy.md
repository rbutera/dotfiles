# Keybind Philosophy

Design principles for the NaviDE keyboard layout. Intended as a reference for future WM migrations (Niri, MangoWC, etc.) — the *mental model* is portable even when specific bindings are not.

---

## Core principle: tap into gaming muscle memory

Keybinds should feel reflexive, not learned. Where a key already has a strong association from gaming or prior tools, lean into it rather than fighting it. The goal is zero cognitive load — the right key should feel obvious.

---

## Key families

### The grave key — "summon an overlay"

Muscle memory source: CS:GO (and most Source engine games) use grave/tilde to drop down the console — a quick-access overlay that appears on top of gameplay without disrupting it.

| Key | Action | Mental model |
|---|---|---|
| `grave` | Scratchpad toggle | Your console — drop-down terminal, quick notes, ad-hoc tools |
| `Hyper+grave` | Quickshell overlay | System overlay — widgets, status, system-level panels |

Both are "summon something on top of your workspace". The grave key family owns this concept.

The scratchpad auto-seeds with a terminal when empty, but is general-purpose — any window can be sent there. It's your quick-access layer, not specifically a terminal drawer.

### Hyper = the app layer

All app launchers live on Hyper. The letter is always mnemonic. Every binding uses focus-or-launch: focus the existing window if running, launch if not.

| Key | App | Mnemonic |
|---|---|---|
| `Hyper+B` | Browser | B for browser |
| `Hyper+C` | Code editor | C for code |
| `Hyper+D` | Discord | D for Discord |
| `Hyper+K` | Calendar | K sounds like "cay" = C for calendar |
| `Hyper+O` | File manager | O for open |
| `Hyper+P` | 1Password quick access | P for password |
| `Hyper+Shift+P` | 1Password toggle | — |

Terminal is the exception — it lives on Super because it's the most fundamental tool:

| Key | Action |
|---|---|
| `Super+Return` | Focus/launch terminal (smart) |
| `Hyper+Return` | Always launch new terminal instance |

**focus-or-launch script** (`custom/scripts/focus-or-launch.sh`): takes a window class regex and a launch command. Checks `hyprctl clients` for a matching window; focuses it if found, dispatches exec if not.

### ESDF — navigation and resize (not HJKL, not arrow keys)

ESDF keeps the left hand's home row resting position closer to the modifier keys. Mirrors WASD from gaming but shifted one key right, freeing up A for sidebar.

The same directional keys serve three escalating purposes with escalating modifiers — borrowed from the vim/tmux model where `Ctrl+W h/j/k/l` and `Ctrl+W H/J/K/L` do related but distinct things:

| Keys | Action |
|---|---|
| `Super+E/S/D/F` | Focus up/left/down/right |
| `Super+Shift+E/S/D/F` | Move window up/left/down/right |
| `Super+Alt+E/S/D/F` | Resize window up/left/down/right (dwindle layout) |

`Super+Alt` is comfortable on the Dygma: Alt on right thumb cluster, Super on left.

**Split ratio (master layout):** `Super+H/L` — shrink/grow the master column. Carried over from Amethyst muscle memory. In master layout, resize is one-axis only (master vs slave proportion); the up/down dimension is managed automatically. `Super+Alt+ESDF` is therefore most useful in dwindle.

### The sidebar pair — A and G

A (far left of home row) = left sidebar. G (just right of center) = right sidebar. Spatial: the keys mirror the screen positions of the panels.

| Key | Action |
|---|---|
| `Super+A` | Left sidebar |
| `Super+G` | Right sidebar |

### Hyper modifier — "same thing, different reach"

The Dygma keyboard's hyper thumb key sends `Ctrl+Alt+Super`. It's used for:
- System/window operations that need a heavier modifier (fullscreen, monitor focus, layout toggle)
- Workspace number mirrors (same as `Super+N` but reachable without leaving home row)
- The grave key family (see above)

Hyper is NOT used to mirror navigation (ESDF) — those mirrors were removed as redundant. `Super+ESDF` is sufficient.

---

## Modifier semantics

| Modifier | Semantic |
|---|---|
| `Super` | Primary actions — apps, focus, navigation |
| `Super+Shift` | Same category, destructive or secondary variant (close window, move window, send to workspace) |
| `Hyper` (Ctrl+Alt+Super) | System-level or layout operations; gravity of action is higher |
| `Hyper+Shift` | Hyper-level destructive/secondary variants |
| `Ctrl+Alt` | External tools with their own conventions (1Password) |

---

## Things deliberately avoided

- **HJKL navigation:** Associated with Vim, not with spatial/gaming reflexes. ESDF was chosen instead.
- **Hyper+ESDF nav mirrors:** Removed — they duplicated `Super+ESDF` with no ergonomic benefit once the Dygma hyper key thumb position was considered.
- **Suspend on an easy chord:** `Super+Shift+L` for suspend is dangerous (adjacent to other bindings). Needs to move somewhere that requires deliberate intent.
- **Multiple keys for the same action:** Every action should have exactly one canonical binding. Aliases create uncertainty about which one "counts".

---

## For future WM migrations

When configuring a new WM, map these concepts first:

1. **Grave key family** — does the WM have a scratchpad/special workspace concept? Map `grave` to it.
2. **ESDF focus/move** — find the focus/move dispatchers and bind to ESDF.
3. **A/G sidebar pair** — if the WM has sidebar widgets, bind spatially.
4. **Return for terminal** — `Super+Return` smart launch, `Hyper+Return` force launch.
5. **Hyper for system ops** — fullscreen, layout toggle, monitor focus.

The specific dispatcher syntax changes; the mental model doesn't.
