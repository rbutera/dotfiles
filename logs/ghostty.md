# Ghostty config changes log

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
