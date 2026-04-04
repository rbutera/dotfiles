# Hyprland — Notes & Pain Points

Field notes from daily use on NaviDE (mondo, CachyOS, 3-monitor setup).
See also: `docs/navide-monitor-usage.md`, `docs/keybind-philosophy.md`.

---

## Gotchas & Institutional Knowledge

### end-4/dots-hyprland upstream keybind conflicts

All custom keybinds live in `dot_config/hypr/custom/keybinds.conf`. This file is loaded
*after* the upstream end-4 keybinds, which means conflicts silently fire both bindings.

**Always unbind upstream bindings before setting your own.** The unbind section at the
top of `keybinds.conf` is the canonical list. When adding a new keybind, check for
upstream conflicts first:

```bash
grep -r "Super.*,.*YOURKEY\b" ~/.config/hypr/hyprland/keybinds.conf
```

**Duplicate bindings are especially insidious for toggles** — if play/pause fires twice, Spotify plays then immediately pauses. The symptom is "key does nothing" rather than "wrong thing happened".

Common upstream bindings that have already bitten us:
- `Super+J` → barToggle (quickshell)
- `Super+K` → oskToggle (on-screen keyboard)
- `Super+M` → mediaControlsToggle
- `Super+Shift+M` → mute sink
- `Super+Alt+S` → movetoworkspacesilent special (fired alongside our resizeactive)
- `Super+Alt+F` → fullscreenstate 0 3
- `Super+Shift+S` → screenshot (fired alongside our movewindow)

### Quickshell dock appears on all monitors when focusing empty monitor C

When `focusmonitor DP-2` is dispatched and C has no windows, the dock reveals on all
monitors. This is **expected behavior**, not a keybind collision.

Root cause: `Dock.qml` line 30:
```qml
property bool reveal: ... || (!ToplevelManager.activeToplevel?.activated)
```
The dock reveals whenever there is no active toplevel (focused window). Focusing an
empty monitor means no active toplevel → all dock instances reveal. The dock hides
as soon as any window is focused. Accepted as-is.

### chezmoi: scripts must have `executable_` prefix

Files in `dot_config/hypr/custom/scripts/` must be named `executable_*.sh` in the
chezmoi source directory, or they deploy as non-executable and all keybinds calling
them silently fail with exit 126.

### Applying individual hypr config files without 1Password

`chezmoi apply ~/.config/hypr/custom/keybinds.conf` is safe without a 1Password session
because none of the hypr custom files use `onepasswordRead`. Always apply + reload after
changes:
```bash
chezmoi apply ~/.config/hypr/custom/keybinds.conf && hyprctl reload
```

---

## Pain Points / Reasons to Try MangoWC or Niri

### Layout is global, not per-monitor or per-workspace

`general { layout = ... }` applies to the entire compositor. There is no workspace rule
or monitor rule that sets dwindle on one monitor while master runs on another simultaneously.

**Practical impact:** Monitor B (vertical, HDMI-A-2) works better with dwindle, but
switching B to dwindle forces A and C to dwindle too. The workaround (auto-switch layout
on monitor focus keybind) is a hack, not a solution — it breaks any workflow where you
move windows between monitors without refocusing via keybind.

MangoWC and Niri both support per-workspace or per-monitor tiling rules natively.
This is a meaningful quality-of-life gap for multi-monitor setups with mixed orientations.
