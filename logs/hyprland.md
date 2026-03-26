# Hyprland / end-4 (NaviDE) config changes log

## 2026-03-26 — Initial Hyprland setup with end-4/dots-hyprland (NaviDE)

### Problem
Switching from KDE Plasma to Hyprland using end-4/dots-hyprland (Illogical Impulse)
as the desktop shell. Need to protect chezmoi-managed dotfiles during installation,
configure multi-monitor setup, custom keybinds, and integrate existing tools.

### Changes

#### Phase 1: iNiR cleanup
- Removed niri package + seatd dependency
- Deleted all iNiR configs (~342MB): niri, quickshell, illogical-impulse, state
- Removed theme spillover: starship ii-palette, lazygit ii-theme, ghostty ii-auto,
  btop ii-auto, vesktop ii-midnight, niri-portals.conf

#### Phase 2: end-4 fork with chezmoi protection
- Cloned end-4/dots-hyprland to `~/dev/illogical-impulse`
- Forked to `rbutera/dots-hyprland`, branch `navi-de`
- Patched `3.files-legacy.sh`: excluded kitty, starship.toml, zshrc.d from installer rsync
- Patched `illogical-impulse-fonts-themes/PKGBUILD`: removed darkly-bin and
  adw-gtk-theme-git from meta-package deps to avoid pacman file conflicts
- Added darkly + adw-gtk-theme provider guards in `install-deps.sh`
- Added `tests/navide-guards.sh` to verify all guards

#### Phase 3: Custom keybinds (Keyboard-no-Jutsu)
- Replaced `custom/keybinds.conf` with Dygma-aware Navi Linux overrides
- Two layers: Super (apps/windows/system) and Hyper (Ctrl+Alt+Super for WM)
- All upstream binds that are redefined are explicitly unbound first
  (duplicates with `global` dispatcher break quickshell IPC)
- Cheatsheet sections use `#!` (columns) and `##!` (sections) format
- Redundant/hardware binds marked `# [hidden]` to keep cheatsheet clean

#### Phase 4: Cheatsheet Arch icon for Hyper
- Modified `CheatsheetKeybinds.qml` to detect Ctrl+Alt+Super combo and
  collapse into single Arch icon (U+F303) from Nerd Fonts
- Note: tried `$hyper` variable approach first but Hyprland's variable
  expansion caused infinite recursion (`$hyper = $hyper` after replace-all)

#### Phase 5: Monitor layout
- DP-1 (LG Ultragear 4K 240Hz) = monitor A, main, at (2560, 0)
- HDMI-A-2 (LG SDQHD 2560x2880) = monitor B, left, at (0, 648) — 30% down
- DP-2 (Samsung 4K 60Hz) = monitor C, above A, flipped 180° (transform 2)
- All at scale 1, no UI scaling
- Hardware cursors disabled (`cursor:no_hardware_cursors = true`) — required
  for flipped monitor to avoid bugged cursor canvas

#### Phase 6: Workspace assignments
- WS 1 on A (default), WS 2 on B (default), WS 3 on C (default)
- WS 4-6 overflow onto A

#### Phase 7: Input settings
- Keyboard layout: GB (override upstream US in `custom/general.conf`)
- Cursor sensitivity: -0.25
- Acceleration: flat (disabled)

#### Phase 8: Quickshell config (`config.json`)
- Terminal: ghostty (was kitty)
- Bar: only on DP-1 and HDMI-A-2 (not on flipped monitor C)
- Workspace number map: A, B, C, 4, 5, 6
- Overview: scale 0.12, 4 columns × 2 rows (was 0.18, 5×2)
- Pinned apps: ghostty, vesktop, obsidian, vivaldi, vscode, 1password,
  mpv, spotify, zen-browser, dolphin
- `TERMINAL` env var overridden to `ghostty` in `custom/env.conf`

#### Phase 9: 1Password integration
- Autostart: `exec-once = 1password --ozone-platform-hint=wayland --silent`
- Quick access: `Ctrl+Alt+P` → `1password --ozone-platform-hint=wayland --quick-access`
- Toggle main window: `Ctrl+Alt+Shift+P` → `1password --toggle`
- **Critical fix**: `--ozone-platform-hint=wayland` flag required for quick access
  to work reliably on Hyprland. Without it, Electron uses XWayland and the popup
  closes immediately on mouse movement due to focus loss. Found via 1Password
  community thread, not a Wayland limitation.

#### Phase 10: KDE Wallet for Vivaldi
- `kwalletd6` added to `custom/execs.conf` — Vivaldi needs it for keystore
- Vivaldi SingletonLock stale symlink had to be manually removed after crash

#### Phase 11: Ghostty config
- Removed transparency (`background-opacity`, `background-blur`)
- Compact tabs: `gtk-wide-tabs = false`, `gtk-toolbar-style = flat`
- Custom CSS (`style.css`): zeroed `min-height` on headerbar, tab, tabbox
- GTK font changed to Geist 9 via `gsettings`

#### Phase 12: Package conflict resolution during install
- `go-yq` conflicts with `yq`: `sudo pacman -Rdd yq`
- `adw-gtk-theme-git` conflicts with `adw-gtk-theme`: `sudo pacman -Rdd adw-gtk-theme`
- `illogical-impulse-quickshell-git` conflicts with `quickshell`: `sudo pacman -Rdd quickshell`
- Removed `ly` display manager (SDDM already enabled)

#### Phase 13: chezmoi import
- Imported `~/.config/hypr/custom/*` (keybinds, env, general, execs, rules)
- Imported `~/.config/hypr/monitors.conf`, `workspaces.conf`
- Imported `~/.config/ghostty/style.css`
- Upstream end-4 files intentionally NOT managed by chezmoi

### Notes
- The `global` dispatcher in Hyprland doesn't work when the same bind exists
  in both upstream and custom keybinds — must `unbind` first
- `hyprctl reload` resets the submap; need `hyprctl dispatch submap global`
  after every reload to restore keybind functionality
- QuickShell must be restarted with `Ctrl+Super+R` after config.json changes
- Never launch quickshell from bash background (`qs -c ii &`) — use
  `hyprctl dispatch exec "qs -c ii"` to avoid duplicate instances
