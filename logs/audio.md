# Audio Setup Log

## 2026-04-08 — EasyEffects, audio switching, mic processing chain

**Problem:** Needed full audio pipeline: output EQ for Truthear Pure headphones (via Audient EVO4), input mic processing for Elgato Wave DX (radio voice style), device switching between EVO4 headphones and FiiO speakers, and system tray control.

**Changes:**

### Output EQ — EasyEffects preset `evo4-eq`

- Created `~/.local/share/easyeffects/output/evo4-eq.json` — 10-band parametric EQ converted from a Peace preset for Truthear Pure headphones
- -3.5dB preamp, bands tuned per original Peace profile, band 8 (11200Hz) muted
- Created `~/.local/share/easyeffects/output/flat.json` — empty effects chain for non-EVO4 devices
- EasyEffects auto-profile switching configured (via GUI): loads `evo4-eq` when EVO4 is default sink, falls back to `flat` for other devices

### Input mic processing — EasyEffects preset `wave-dx-radio`

- Created `~/.local/share/easyeffects/input/wave-dx-radio.json` — full voice chain:
  - **RNNoise** — AI noise suppression
  - **Gate** — -45dB threshold, -24dB reduction, 2ms attack / 50ms release
  - **Equalizer** — 8-band "deep radio voice" tuning: +4.5dB at 100Hz, +3dB at 220Hz, -1.5dB at 800Hz, +2dB at 2.5kHz, hi-pass at 60Hz, lo-pass at 16kHz
  - **Compressor** — downward, -22dB threshold, 4:1 ratio, 6dB makeup, 8ms attack / 120ms release
  - **De-esser** — wide mode, -18dB threshold, 3:1 ratio, 6kHz focus
  - **Limiter** — Herm Thin mode, -1dB threshold, 5ms lookahead
- Preset format reverse-engineered from EasyEffects v8 C++ source (no docs exist) — required string enums, `#0` plugin suffixes, nested sidechain objects, `curve-threshold` instead of `threshold` for gate, etc.

### EasyEffects dependencies

- Installed: `lsp-plugins`, `calf`, `zam-plugins`, `mda.lv2`, `deepfilternet` — required for LSP EQ, compressor, and other effects to work without "illegal increment" errors

### EasyEffects autostart

- Created `~/.config/autostart/easyeffects-service.desktop` — starts EasyEffects in service mode (no GUI) on login

### Audio device switching

- Created `~/bin/audio-switch` — CLI tool to toggle default PipeWire sink between EVO4 (headphones) and FiiO (speakers) via `wpctl set-default`
- Created `~/bin/audio-tray` — PyQt5 system tray app: left-click toggles devices, right-click menu for explicit selection, 5s polling for icon sync. Uses Papirus-Dark theme icons.
- Created `~/.config/autostart/audio-tray.desktop` — autostart for tray app

### Mic testing

- Created `~/bin/mic-test` — A/B comparison script: records raw from EVO4 then processed from Easy Effects Source, plays both back via mpv

### FiiO USB stability

- Created `/etc/udev/rules.d/99-fiio-no-autosuspend.rules` — disables USB autosuspend for FiiO DigiHug (vendor 1852, product 7022) to fix intermittent audio dropouts caused by 2-second autosuspend delay

**Known issues:**

- FiiO speakers intermittently produce no audio — sometimes works after reboot, sometimes doesn't. USB autosuspend rule helps but doesn't fully resolve it.
- EVO4 volume reports as 0 in wpctl due to surround-40 channel mapping (4 ALSA channels, only 2 physical outputs) — setting integer volume manually works fine, hardware knob controls actual volume independently.
