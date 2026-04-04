# NaviDE — Monitor Usage & Layout Philosophy

Field notes on how this 3-monitor setup is actually used, and the reasoning behind layout decisions. Intended as a reference both for Hyprland config and for future window manager explorations (Niri, MangoWC, etc.) — the *philosophy* is WM-agnostic even when the implementation details are not.

---

## Physical Setup

```
        [ C — DP-2, 4K 60Hz, above A ]
[ B — HDMI-A-2 ]  [ A — DP-1, 4K 240Hz, main ]
```

---

## Monitor A — DP-1 (main, 4K 240Hz) · Workspaces 1–4

**Role:** Primary focus / work surface.

**Typical contents:**
- IDE or terminal in master (center column)
- Browser to one side for reference
- Second terminal or supporting tool on the other side
- Sometimes browser becomes master when web work is the primary focus

**Layout philosophy:**
- **Dominant center, peripheral sides.** The master window is the thing being worked on. Side columns exist for peripheral vision — glanceable, not primary focus.
- **mfact = 0.5** was chosen because it's consistent: master is always exactly half the screen regardless of slave count. With 2 windows it's a clean 50/50 split; with 3 windows it's 50% center + 25% each side. No jarring resize as windows are opened/closed.
- Equal thirds (0.333) was considered and rejected — it implies equal importance across all columns, which doesn't match the actual workflow.
- **Center master orientation** kicks in at 3 windows (slave_count_for_center_master = 2). With 1 slave, it falls back to a left/right split, which is the right call — centering a window with a single sidebar looks odd.

**Promote-to-master is a first-class action.** The master window changes depending on focus — IDE most of the time, browser when deep in web research. A fast, natural keybind for "make this window master" is essential. Without it, the layout is rigid and frustrating.

**Hyprland specifics:**
- `orientation = center` via workspace rules
- `mfact = 0.5`, `slave_count_for_center_master = 2`, `center_master_fallback = left`
- `new_status = slave` — new windows don't displace the master

---

## Monitor B — HDMI-A-2 (2560×2880, vertical) · Workspaces 5–7

**Role:** Ambient / reference / communication layer.

**Physical reality:** Vertical orientation. This is effectively two 16:9 monitors stacked on top of each other (~2560×1440 each half). Left/right tiling on a vertical monitor produces two tall narrow columns that are hostile to most content. Top/bottom stacking produces two sensible landscape-oriented panes — treat it like two monitors, not one wide one rotated.

**Typical contents:**
- Discord / Slack / messaging (often full-height, single window)
- Documentation and wikis for reference while working on A
- Dashboards and monitoring tools
- Secondary browser when A is fully occupied

**Layout philosophy:**
- Top/bottom stacking is the only sensible orientation for a vertical monitor with tiling.
- Rarely needs more than 2 windows. Often just 1 full-height window (Discord).
- This monitor is ambient — it should never demand focus, just support it.

**Hyprland specifics:**
- `orientation = top` via workspace rules
- mfact tuning TBD — default 0.5 gives two equal halves which is a reasonable start

---

## Monitor C — DP-2 (4K 60Hz, above A) · Workspaces 8–10

**Role:** Background / overflow / media.

**Typical contents:**
- Movie or TV show running in background while working
- Spotify
- Overflow dashboards when B is occupied by something else
- Occasionally browser or parallel work when needing extra real estate beyond A

**Layout philosophy:**
- Usually 1 fullscreen window. The tiling layout almost never matters here.
- When used for overflow work, a simple 2-window split is sufficient.
- Center master orientation is configured for consistency but is rarely exercised.

**Hyprland specifics:**
- `orientation = center` via workspace rules (matches A; academic in practice)

---

## General Layout Philosophy (WM-agnostic)

These principles held in Amethyst on macOS and carry forward:

**The 3-column center layout is the sweet spot for a wide/4K primary monitor.**
1 window: fills the screen. 2 windows: left/right split. 3 windows: center master + left slave + right slave. This covers ~90% of actual usage.

**Master proportion should be consistent across window counts.**
A layout that changes the master window's size when you open a third window is disorienting. Choose an mfact where the master size is stable — 0.5 achieves this because the center column stays at 50% whether you have 2 or 3 windows.

**"Promote to master" is as important as navigation.**
The ability to instantly make any window the master is what makes a master layout feel fluid rather than rigid. It should be a single fast keybind, not a sequence of swaps.

**Vertical monitors need top/bottom tiling, not left/right.**
A vertical monitor with left/right tiling produces unusably narrow columns. Top/bottom stacking treats the monitor for what it physically is: two landscape viewports stacked. Any WM configuration for a vertical monitor should default to this.

**Side columns are for peripheral vision, not primary use.**
Design the layout for the case where you're deeply focused on the master. Side columns should be readable at a glance but not optimised for active use — they get promoted to master when they need attention.

---

## Prior art: Amethyst (macOS)

Amethyst uses a different model — fully automatic layout with no explicit master promotion. Windows are placed by algorithm. The closest layout to this setup was the 3-column-center layout: master in center, slaves flanking left and right.

Key difference from Hyprland: in Amethyst, you couldn't easily "focus" a layout on one window. Windows were more equal. The Hyprland master model with explicit promotion is more intentional and better suited to deep-focus work.
