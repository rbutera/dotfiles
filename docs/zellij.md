# Zellij — Research & Decision Notes

Not yet configured. These are pre-implementation findings to inform a future setup.

---

## Plugin shortlist

From [awesome-zellij](https://github.com/zellij-org/awesome-zellij):

| Plugin | Purpose | Decision |
|---|---|---|
| **monocle** | Fuzzy find file names and contents | ✅ install |
| **zellij-sessionizer** | Create/switch sessions from folder names (fuzzy finder) | ✅ install |
| **zellij-worktree** | Git worktree management | ✅ install |
| **zellij-forgot** | Keybinding cheatsheet overlay | ✅ install |
| **zellij-autolock** | Auto-lock zellij when focused app (Neovim, lazygit, etc.) needs full keyboard | ✅ install |
| **vim-zellij-navigator** | Unified `Ctrl+h/j/k/l` nav across Neovim splits and Zellij panes | ✅ install (pairs with autolock) |
| **zjstatus** | Fully configurable, themeable status bar | 🤔 consider |
| **zellaude / zellij-attention** | Claude Code activity indicators on tabs | 🤔 consider |

**autolock + vim-zellij-navigator** are complementary, not redundant:
- autolock locks Zellij when Neovim is focused so Neovim gets all keypresses
- vim-zellij-navigator handles the cross-boundary move (`Ctrl+l` from inside Neovim → adjacent Zellij pane) without leaving Neovim

---

## Vi copy mode — known gap

There is **no vi copy mode plugin** for Zellij. This is a widely-complained-about gap (open issue since 2021).

**Official workaround:** `EditScrollback` — dumps scrollback to a temp file and opens it in `$EDITOR` (Neovim). You get full vi motions and yank, but in a separate buffer rather than in-place. Bind to `e` in scroll mode.

This is real friction compared to tmux's `copy-mode-vi`. Factor into decision of whether to switch at all.

---

## OSC52 / clipboard notes

- Zellij emits OSC52 natively for its own copies (mouse selection → terminal clipboard)
- **OSC52 forwarding from child processes is broken** (Neovim 0.10+ cannot detect clipboard support inside Zellij — issue #3951, open)
- OSC52 paste is intentionally blocked for security reasons
- **Recommended:** set `copy_command = "~/bin/osc52copy"` — overrides default, uses the existing context-aware script (Wayland vs SSH)

---

## Tmux settings to port

| Setting | Tmux | Zellij equivalent | Notes |
|---|---|---|---|
| Vi mode | `mode-keys vi` | No direct equivalent | Use `EditScrollback` workaround |
| Mouse | on | `mouse_mode true` | Built-in |
| copy_on_select | MouseDragEnd → osc52copy | `copy_on_select true` | Matches current muscle memory |
| Clipboard | `~/bin/osc52copy` | `copy_command "~/bin/osc52copy"` | Required for SSH clipboard |
| Session resurrection | tmux-resurrect + continuum (5min) | Built-in `session_serialization` | Set `serialization_interval` |
| Prefix | `C-b` / `C-Space` | Modal modes (no prefix) | `Ctrl+g` to toggle locked mode; consider `Ctrl+Space` to mirror tmux |
| Pane nav | `prefix+hjkl` | Move mode + hjkl | Keep consistent with Neovim/tmux |
| Tab nav | `C-h/C-l`, `Tab` last | Remap in normal mode | Keep same |
| Splits | `-` horizontal, `_` vertical | Remap in pane mode | Keep both plus built-in defaults while settling in |
| allow-passthrough | on | Built-in (always on) | No action needed — zellij passes OSC sequences through |
| Scrollback | 10000 lines | `scroll_buffer_size 10000` | Direct port |

---

## Theme

Catppuccin Mocha — matches tmux, kitty, ghostty, nvim.
Zellij has a built-in catppuccin theme: `theme "catppuccin-mocha"`.

---

## Open questions before implementing

1. **Locked mode key** — default `Ctrl+g` or remap to `Ctrl+Space` (mirrors tmux secondary prefix)?
2. **Default layout** — single pane, or a named layout with sessionizer?
3. **Replace tmux or run alongside?** — Some tools (tmux-continuum, existing muscle memory) make a hard cut risky. Could run zellij for new projects and tmux for existing sessions during transition.
