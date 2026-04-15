# Ghostty config changes log

## 2026-04-15 — Cmd+D and Cmd+C send Ctrl+D / Ctrl+C on macOS (muscle memory aliases)

### Problem
Coming from Windows/Linux, `Ctrl+D` (EOT — exit shell, readline delete-char) and `Ctrl+C` (SIGINT — interrupt) are muscle memory. On macOS, Cmd is the equivalent meta modifier for most shortcuts, so hitting `Cmd+D` / `Cmd+C` felt natural but did the wrong thing (Cmd+D defaulted to `new_split:right`, Cmd+C copied the selection).

### Changes
`dot_config/ghostty/config.tmpl` darwin-only block, alongside the quick-terminal keybinds:
```
keybind = super+d=text:\x04        # Cmd+D → Ctrl-D (EOT)
keybind = super+c=text:\x03        # Cmd+C → Ctrl-C (SIGINT)
keybind = super+shift+c=copy_to_clipboard
```
Ghostty's `text:` action sends raw bytes to the pty. `\x04` = EOT, `\x03` = ETX — identical to what `Ctrl-D` / `Ctrl-C` produce on a keyboard. Linux branches are unaffected — there the native `ctrl+d` / `ctrl+c` already work and these bindings aren't emitted.

Because `Cmd+C` is now SIGINT, the copy action moves to `Cmd+Shift+C`. This matches the long-standing Linux terminal convention (gnome-terminal, Konsole, xterm with extensions all do `Ctrl-C` = interrupt, `Ctrl-Shift-C` = copy) — so the whole macOS keymap now mirrors Linux with Cmd in place of Ctrl.

### Notes
- Ghostty has no "smart" fallthrough where `Cmd+C` copies if there's a selection and sends SIGINT otherwise — the binding is static. Committing fully to SIGINT here, copy lives on `Cmd+Shift+C`.
- Overridden defaults: macOS `Cmd+D = new_split:right` and `Cmd+C = copy_to_clipboard`. If a split-right shortcut is wanted later, rebind it explicitly — note `super+shift+d` is taken by `jump_to_prompt:1`.
- Same pattern can be extended to more control chars later if useful: `\x1a` (Ctrl-Z, SIGTSTP), `\x15` (Ctrl-U, kill line back), `\x17` (Ctrl-W, kill word back), `\x0c` (Ctrl-L, clear). Not doing that now.

## 2026-04-15 — Switch macOS to JetBrainsMono NFM + font-thicken

### Problem
After trying GeistMono Nerd Font on macOS at 10pt, rendering looked off and lowercase `f` was nearly unreadable (likely the `ff`/`fi` ligature collapsing at small sizes). Wanted to revert to JetBrains Mono — but use the Nerd Font variant this time so icons/glyphs work — and address Ghostty's thin macOS rendering.

### Changes
- `dot_config/ghostty/config.tmpl` darwin branch: `font-family = JetBrainsMono NFM` (Homebrew cask `font-jetbrains-mono-nerd-font`, already installed; abbreviated family name like Geist).
- Added `font-thicken = true` on darwin only. Ghostty's CoreText rendering is intentionally thinner than Apple's Terminal/iTerm because it skips the legacy font-smoothing dilation; `font-thicken` re-enables it. macOS-only setting (no-op on Linux).
- Linux branches unchanged (Arch still uses GeistMono Nerd Font Mono).

## 2026-04-15 — Bump font size + GeistMono on macOS

### Problem
`font-size = 8` (set for Linux/HiDPI) renders too small on Mac displays. Also, the existing GeistMono Nerd Font branch only activated on Arch — macOS was falling back to JetBrains Mono.

### Changes
- Installed `font-geist-mono-nerd-font` via Homebrew cask on macOS.
- Templated `font-size` in `dot_config/ghostty/config.tmpl`: `10` on darwin, `8` elsewhere. Trying 10 on macOS as a starting point.
- Added darwin branch for `font-family`: `GeistMono NFM`. The Homebrew cask uses the abbreviated family name (`GeistMono NFM`) as the primary `name` table family, while the AUR/Linux package exposes the full `GeistMono Nerd Font Mono` — so the two platforms need different `font-family` strings even though the underlying font is identical.

## 2026-04-08 — Fix write_scrollback_file keybind

`write_scrollback_file` requires an argument (`:open` or `:paste`). Changed to `write_scrollback_file:open` to fix `keybind: unknown error error.InvalidFormat` validation error.

## 2026-04-08 — Power user config overhaul

### Changes
- **Background blur**: `background-blur = 20` (complements existing 0.85 opacity)
- **Clipboard**: `clipboard-read/write = allow` (silent OSC 52 for neovim etc), `clipboard-trim-trailing-spaces = true`
- **Shell integration**: Explicitly enabled `cursor,sudo,title,ssh-env,ssh-terminfo` (sudo + SSH features were off by default)
- **Split navigation**: hjkl via `ctrl+shift` (Linux) / `cmd+shift` (macOS), plus zoom toggle (`+z`), unfocused split dimming (0.85), focus-follows-mouse
- **Prompt jumping**: `ctrl/cmd+shift+e` (prev) / `+d` (next)
- **Utility keybinds**: scrollback-to-file (`+o`), command palette (`+p`), reload config (`+r`), copy URL (`+u`)
- **Quick terminal**: macOS only, `ctrl+cmd+alt+grave` — dropdown/quake mode
- **Template refactor**: Added `$mod` variable (`ctrl` on Linux, `super` on macOS) for all keybinds

## 2026-04-08 — Set GeistMono Nerd Font on Arch systems

### Problem
Ghostty was using the built-in JetBrains Mono. User wanted GeistMono Nerd Font Mono instead (already installed via system packages).

### Changes
- Added Arch-conditional `font-family = GeistMono Nerd Font Mono` to `dot_config/ghostty/config.tmpl`. Non-Arch platforms still fall back to the built-in JetBrains Mono.

## 2026-03-28 — Template Ghostty shell path for macOS vs Linux

### Problem
Ghostty config was a plain file, but the shell path differs by platform. Linux should continue using `/usr/bin/zsh`, while macOS should use Homebrew's zsh at `/opt/homebrew/bin/zsh`.

### Changes
- Renamed `dot_config/ghostty/config` to `dot_config/ghostty/config.tmpl`.
- Replaced the hardcoded `command` line with a chezmoi template conditional:
  - macOS: `/opt/homebrew/bin/zsh`
  - Linux: `/usr/bin/zsh`

## 2026-03-26 — Add transparent background (80% opacity)

### Problem
User wanted a transparent terminal background.

### Changes
- Added `background-opacity = 0.8` to `dot_config/ghostty/config` (later adjusted to 0.95 by user).

## 2026-03-26 — Enable Hyprland blur for Ghostty

### Problem
With a transparent background, Ghostty needs blur enabled in Hyprland to look good. NaviDE's default rules disable blur for all windows (`no_blur on` on `class .*`), so a per-app override is needed.

### Changes
- Added windowrules to `dot_config/hypr/custom/rules.conf`:
  - `no_blur off` for Ghostty's class (`com.mitchellh.ghostty`) to override the global disable
  - `blur_popups on` for Ghostty popups
