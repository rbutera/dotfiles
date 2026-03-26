# niri / iNiR config changes log

## 2026-03-25 — Fix keyboard layout and ghostty theme after iNiR install

### Problem
After installing iNiR (Quickshell desktop shell for Niri), two issues:

1. **Keyboard layout was US instead of UK** — iNiR's default niri config sets
   `xkb { layout "us" }`, breaking symbol input for a GB keyboard.

2. **Ghostty lost Catppuccin Mocha theme** — iNiR's matugen theming appended
   `theme = ii-auto` to the deployed `~/.config/ghostty/config`, overriding the
   existing `theme = Catppuccin Mocha` line. The chezmoi source was unaffected.

### Changes
- `~/.config/niri/config.kdl`: changed `layout "us"` to `layout "gb"`
- `~/.config/ghostty/config`: removed the appended `theme = ii-auto` line

### Notes
- Niri config is managed by iNiR, not chezmoi.
- iNiR's matugen may re-append the ghostty theme override on wallpaper changes —
  check iNiR's matugen templates if this recurs.

## 2026-03-26 — Full iNiR removal, pivot to Hyprland/end-4

### Problem
Decided to switch from niri to Hyprland (end-4/dots-hyprland / Illogical Impulse).
Need to fully remove all iNiR remnants before installing the new desktop.

### Changes
Removed:
- `niri` + `seatd` packages (pacman -Rns)
- `~/.config/niri/`, `~/.config/quickshell/`, `~/.config/illogical-impulse/`
- `~/.local/state/quickshell/` (289MB — Python venv + runtime state)
- Theme spillover: starship ii-palette, lazygit ii-theme, ghostty ii-auto,
  btop ii-auto, vesktop/Vesktop ii-midnight themes
- `~/.config/xdg-desktop-portal/niri-portals.conf`
- `~/iNiR` repository

### Notes
- Shell configs (zshrc/zprofile/zshenv) were clean — the `INIR_PRESERVE_ZSH`
  guard on the NaviDE branch worked correctly.
- iNiR NaviDE patches saved to `/tmp/inir-navide-patches/` before repo deletion,
  for reference when patching end-4.
- Replacement: forked end-4/dots-hyprland to `rbutera/dots-hyprland`, branch
  `navi-de`, local clone at `~/dev/illogical-impulse`.
