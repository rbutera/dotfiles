# Hyprland / end-4 (NaviDE) config changes log

## 2026-04-04 — Post-overhaul fixes and additions

### Changes

#### Media key play/pause fixed
- `XF86AudioPlay` and `XF86AudioPause` were bound twice (upstream + custom), causing
  play-pause to toggle twice and cancel itself out. Symptom: key appeared to do nothing.
  Fixed by adding unbinds for `XF86AudioPlay`, `XF86AudioPause`, `XF86AudioNext`, `XF86AudioPrev`
  to the custom unbind section. Back/forward worked because doubling a skip is idempotent.

#### Hyper+N → Obsidian (focus-or-launch)
- Added `Control+Alt+Super, N` → `focus-or-launch.sh "obsidian" obsidian`
- Window class confirmed as `obsidian`

#### Master layout: swapwithmaster auto
- `Super+M` updated to `layoutmsg swapwithmaster auto` — toggles intelligently:
  promotes slave to master if slave, cycles master out if already master
- `Super+Shift+M` = focusmaster

#### Master layout J/K binds
- `Super+J/K` = cyclenext/cycleprev (focus cycle through layout order)
- `Super+Shift+J/K` = swapnext/swapprev (reorder in stack)
- Unbound upstream `Super+J` (barToggle), `Super+K` (oskToggle), `Super+M` (mediaControlsToggle),
  `Super+Shift+M` (mute), `Super+Alt+M` (mic mute)

#### Scripts: executable_ prefix fix
- All custom scripts were non-executable — root cause of Super+Shift+1-4 doing nothing
- Renamed all `*.sh` to `executable_*.sh` in chezmoi source

#### Scratchpad toggle fix
- `workspace.name == "special"` check was never matching; fixed to `workspace.id < 0`
- Added flock to prevent race on rapid key presses
- Revised to use `[workspace special silent]` + poll + 200ms settling pause before toggle

#### tmux: allow-passthrough on
- Added `set -g allow-passthrough on` to `dot_tmux/dot_tmux.conf.local`
- Required for opencode and other tools that emit OSC sequences directly

#### Documentation added
- `docs/hyprland.md`: pain points, upstream unbind gotchas, chezmoi/scripts tips
- `docs/quickshell.md`: IPC action names, dock reveal behaviour, config location
- `docs/zellij.md`: research notes and deferred implementation decisions

## 2026-04-04 — Keybind overhaul (NaviDE keyboard-no-jutsu)

### Motivation
Comprehensive keybind redesign to eliminate upstream conflicts from end-4/dots-hyprland,
remove duplicates, and build a coherent mental model grounded in gaming muscle memory.
See `docs/keybind-philosophy.md` for the full design rationale.

### Changes

#### Unbinds
- Unbound all conflicting upstream `Super+*` keys (D, F, K, J, T, E, C, S, Tab, Slash, V, Period, A, N, G, Q, Return, grave, B, H, Semicolon, L, Equal, Minus)
- Unbound `Super+Alt+S/F/A/M/R/Space` (upstream resize/workspace conflicts)
- Unbound `Super+Shift+S` (upstream screenshot conflict with our movewindow)
- Unbound `Super+J/K/M`, `Super+Shift+M`, `Super+Alt+M` (upstream bar/osk/media/mute)

#### App layer (Hyper = focus-or-launch)
- All app launchers on Hyper (Ctrl+Alt+Super): B=browser, C=code, D=Discord, K=calendar, O=file manager, P=1Password
- `Super+Return` = focus/launch terminal (smart); `Hyper+Return` = always new instance
- Focus-or-launch script: checks `hyprctl clients` for class regex, focuses if found, launches if not

#### Navigation (ESDF)
- `Super+ESDF` = focus up/left/down/right
- `Super+Shift+ESDF` = move window up/left/down/right
- `Super+Alt+ESDF` = resize (dwindle layout)
- Removed Hyper+ESDF nav mirrors (redundant)

#### Master layout
- Switched default layout to master (`dot_config/hypr/custom/general.conf`)
- mfact=0.5; workspace orientation rules per monitor: center for A/C, top for B (vertical)
- `Super+H/L` = shrink/grow master split ratio
- `Super+J/K` = cyclenext/cycleprev (focus cycle)
- `Super+Shift+J/K` = swapnext/swapprev
- `Super+M` = `swapwithmaster auto` — toggle: promotes slave to master, or cycles master out if already master
- `Super+Shift+M` = focusmaster

#### Workspace navigation
- `Super+1-4` = local workspace (relative to current monitor via `local-workspace.sh`)
- `Super+Shift+1-4` = move window to local workspace
- Monitor mapping: A (DP-1) ws1-4, B (HDMI-A-2) ws5-7, C (DP-2) ws8-10
- `Hyper+ESDF` = focus monitor spatially (E=above/C, S=left/B, F=main/A)
- `Hyper+Shift+ESDF` = send window to monitor

#### Scratchpad (grave key family — CS:GO console muscle memory)
- `Super+grave` = toggle scratchpad (auto-seeds ghostty terminal if empty)
- `Shift+grave` = send current window to scratchpad
- `Hyper+grave` = quickshell overlay toggle

#### Sidebar pair
- `Super+A` = left sidebar, `Super+G` = right sidebar (spatial: keys mirror panel positions)

#### Layout toggle
- `Hyper+Tab` = toggle between master and dwindle layouts

#### Shell / system
- `Super+Tab` = workspace overview; `Super+Slash` = cheatsheet
- `Super+V` = clipboard; `Super+Period` = emoji picker
- `Hyper+M` / `Hyper+Shift+M` = mute output / mute mic

#### Scripts (new)
- `focus-or-launch.sh`: focus existing window by class regex or launch
- `local-workspace.sh`: relative workspace navigation per monitor
- `toggle-scratchpad.sh`: scratchpad with terminal auto-seed
- `toggle-layout.sh`: master/dwindle toggle
- All scripts fixed with `executable_` prefix in chezmoi source (were non-executable — root cause of Super+Shift+1-4 not working)

#### Dock "appearing on all monitors" non-issue
- `Hyper+E` (focusmonitor DP-2) caused dock to appear on all monitors when C was empty
- Root cause: `Dock.qml` `reveal` condition includes `!ToplevelManager.activeToplevel?.activated`
- Expected quickshell behavior — dock shows when no active toplevel. Accepted as-is.

#### Documentation added
- `docs/keybind-philosophy.md`: design principles, key families, modifier semantics
- `docs/navide-monitor-usage.md`: per-monitor layout intent and WM-agnostic philosophy

## 2026-04-04 — Switch default browser binding to Brave; simplify kanata config

### Changes

- `dot_config/hypr/custom/keybinds.conf`: Super+B now launches `brave` first (was `vivaldi-stable --force-dark-mode`)
- `dot_config/kanata/kanata.kbd`: stripped down to a single purpose — F16 → tap Esc / hold Ctrl+Alt+Super (hyper key). Removed F14/F15/F18 mappings, mod1/mod2/mod3 aliases, and tmux-combo/summon-launcher bindings. Added header comment explaining the Dygma F16 setup.

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
