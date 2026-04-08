# Steam / Gaming Setup Log

## 2026-04-08 — Initial Steam + gaming stack setup

**Problem:** No gaming setup on this Arch/CachyOS machine (RX 9070 XT + Raphael iGPU). Steam requires multilib repo, 32-bit drivers, and locale configuration that weren't present.

**Changes:**

- Enabled `[multilib]` repo in `/etc/pacman.conf` (was commented out)
- Generated `en_US.UTF-8` locale (required by Steam to avoid invalid pointer errors)
- Installed core packages:
  - `steam` — Steam client
  - `lib32-mesa-git` — 32-bit OpenGL/Vulkan from CachyOS (provides lib32-vulkan-radeon, lib32-vulkan-icd-loader)
  - `proton-cachyos` 10.0 — CachyOS-flavored Proton (native build, not SLR)
- Installed gaming tools:
  - `gamemode` + `lib32-gamemode` — Feral GameMode (per-game CPU/GPU optimization)
  - `mangohud` + `lib32-mangohud` — FPS/temp/GPU overlay
  - `gamescope` — Valve micro-compositor (resolution/HDR/frame limiting)
- Set `vm.max_map_count=2097152` persistently via `/etc/sysctl.d/80-gamecompatibility.conf` (default 1048576 is too low for some games)

**Notes:**

- `lib32-mesa-git` from CachyOS repo is required because system runs `mesa-git` — standard `lib32-mesa` and `lib32-vulkan-radeon` conflict with it
- Proton-CachyOS has Wayland support (disabled by default, enable with `PROTON_ENABLE_WAYLAND=1`)
- GameMode has no system service — activates per-game via `gamemoderun %command%`
- Steam launch options for full setup: `MANGOHUD=1 gamemoderun %command%`
