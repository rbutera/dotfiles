# Ghostty config changes log

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
