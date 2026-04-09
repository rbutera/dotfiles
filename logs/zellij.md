# Zellij config changes log

## 2026-04-09 — Initial Zellij setup, ported from tmux

### Motivation
Rai wants to try Zellij as a tmux replacement. Full config created from scratch,
translating the existing tmux keybind workflow from `dot_tmux/dot_tmux.conf` and
`dot_tmux/dot_tmux.conf.local`.

### What was created

**`dot_config/zellij/config.kdl`** — main Zellij config:

Core settings:
- Catppuccin Mocha theme (matching tmux `@catppuccin_flavour 'mocha'`)
- Default shell: zsh
- Mouse mode on (matching tmux `set -g mouse on`)
- Copy on select to system clipboard (matching tmux-yank behavior)
- Scroll buffer 10000 (matching tmux `history-limit 10000`)
- Session serialization on (replaces tmux-resurrect + tmux-continuum)
- Pane frames off (cleaner, more like tmux without borders)
- OSC8 hyperlinks enabled
- Rounded corners enabled

Keybind translation from tmux:

| tmux (prefix = C-Space)      | Zellij equivalent              |
|------------------------------|--------------------------------|
| `prefix + -`  split horiz   | `Alt+-` or Pane mode + `-`     |
| `prefix + _`  split vert    | `Alt+_` or Pane mode + `_`     |
| `prefix + h/j/k/l` navigate | `Alt+h/j/k/l` (direct)         |
| `prefix + H/J/K/L` resize   | Resize mode (`Ctrl+r`) + h/j/k/l |
| `prefix + z`  zoom pane     | `Alt+f` or Pane mode + `z`     |
| `prefix + c`  new window    | `Alt+t` (new tab)              |
| `prefix + n/p` next/prev    | `Alt+]` / `Alt+[`              |
| `prefix + 1-9` go to window | `Alt+1-9` (direct tab access)  |
| `prefix + Tab` last window  | `Alt+Tab`                      |
| `prefix + x`  close pane    | `Alt+x` or Pane mode + `x`     |
| `prefix + d`  detach        | Session mode (`Ctrl+o`) + `d`  |
| `prefix + Enter` copy mode  | Scroll mode (`Ctrl+s`)         |
| `prefix + [` scroll         | Scroll mode (`Ctrl+s`)         |
| `prefix + >/<` swap pane    | Pane mode + `>` / `<`          |
| `prefix + b` list buffers   | N/A (Zellij uses system clip)  |
| `prefix + r` reload config  | Zellij auto-reloads config     |
| `prefix + e` edit config    | Edit file directly             |
| `prefix + m` toggle mouse   | Built-in mouse toggle          |

Modal system:
- Normal mode: most operations via Alt+key (no mode switch needed)
- Pane mode (Ctrl+Space or Ctrl+p): single-key pane ops, then back to Normal
- Tab mode (Ctrl+t): tab management
- Resize mode (Ctrl+r): h/j/k/l resize with Shift variants
- Scroll mode (Ctrl+s): vi-style scrolling with j/k/d/u/f/b/G/g, / for search
- Search mode: n/N for next/prev, c/w/r toggle options
- Session mode (Ctrl+o): detach, quit
- Locked mode (Ctrl+g): prevents accidental commands

Plugins configured:
- Monocle (fuzzy finder): `Alt+m` kiosk mode, `Ctrl+f` floating — loaded from URL
- zellij-worktree (git worktrees): `Alt+g` — loaded from URL
- Harpoon (quick pane bookmarks): commented out, needs local build
- zellij-forgot (keybind cheatsheet): commented out, needs download
- zellij-attention (tab notifications): commented out, needs download

**`dot_config/zellij/layouts/default.kdl`** — default layout:
- Single pane with compact status bar at bottom (like tmux status line)

**`dot_config/zellij/layouts/dev.kdl`** — dev layout:
- 70/30 vertical split with compact status bar
- Launch with `zellij --layout dev`

### tmux features replaced by Zellij built-ins
- tmux-resurrect / tmux-continuum → `session_serialization true`
- tmux-yank → `copy_on_select true` + `copy_clipboard "system"`
- tmux-sensible → Zellij defaults are already sensible
- catppuccin/tmux → `theme "catppuccin-mocha"` (built-in)
- TPM plugin manager → Zellij loads WASM plugins from URLs

### Plugins not yet configured (need manual install)
- **Harpoon**: `rustup target add wasm32-wasip1 && git clone https://github.com/Nacho114/harpoon && cd harpoon && cargo build --release && cp target/wasm32-wasip1/release/harpoon.wasm ~/.config/zellij/plugins/`
- **zellij-forgot**: download from https://github.com/karimould/zellij-forgot/releases
- **zellij-attention**: download from https://github.com/KiryuuLight/zellij-attention/releases
- **zellij-qr-share**: requires Zellij 0.43+ with web UI, build from source or download
