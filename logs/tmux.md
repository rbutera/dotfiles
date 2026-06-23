# tmux config changes log

## 2026-06-23 — Fix copy-paste over SSH for real (passthrough wrap + reattach bug)

### Problem
Copy-paste over SSH failed ~99% of the time on mac/Ghostty — both copy-mode `y`
and mouse highlight-to-yank (both route through `~/bin/osc52copy`). Behaviour
also "changed on reattach" (start tmux locally in the office, SSH in + reattach
from home → broken).

### Diagnosis (evidence, not guess)
Ran three OSC52 emission methods over a live SSH+tmux session and checked which
token reached the mac clipboard: (1) RAW OSC52 to client_tty = FAILED; (2)
tmux-PASSTHROUGH-WRAPPED OSC52 = WORKED; (3) tmux native `load-buffer -w` =
FAILED. So raw OSC52 written to client_tty is swallowed by the tmux layer, and
tmux's native set-clipboard emission also doesn't survive (consistent with a
nested-tmux / client-forward issue). Only the explicit passthrough wrap escapes.

TWO root causes, which is why it was so flaky:
1. **Swallowed OSC52**: `osc52_to_tty()` wrote RAW OSC52 to `#{client_tty}`;
   inside tmux that never reaches the terminal.
2. **Reattach / server-env**: `osc52copy` branched on `$SSH_CONNECTION`/`$SSH_TTY`
   to pick SSH-vs-local. Inside tmux that env is the SERVER's (captured at
   session start). Start tmux locally → no SSH_CONNECTION → it took the `pbcopy`
   branch → copied to the LOCAL (server) clipboard, not the remote client's.
   Reattaching from remote never updates the server env, so it stayed wrong.
   (The debug log showed both "used pbcopy" and "wrote OSC52 to tty" lines —
   the two paths, two scenarios.)

### Solution
**`bin/executable_osc52copy`**:
- `osc52_to_tty()` now wraps OSC52 in tmux's passthrough DCS
  (`\ePtmux;\e\e]52;c;<data>\a\e\\`, inner ESCs doubled) when `$TMUX` is set, so
  tmux forwards it to the active client terminal. Requires `allow-passthrough on`
  (already set in dot_tmux.conf).
- Restructured the main logic: **when `$TMUX` is set, ALWAYS use
  osc52_to_tty** (the active client's terminal is the correct target regardless
  of where the server started or where you resume from). Do NOT branch on
  `$SSH_CONNECTION` inside tmux — that's the reattach bug. pbcopy/wl-copy/xclip
  remain only as the non-tmux fallback.
- Covers all scenarios: start-local-resume-remote, start-remote-resume-local,
  mouse drag, the yank tool — on any OSC52 terminal (Ghostty / Kitty / Windows
  Terminal). OSC52 is also correct for WSL over Windows Terminal (clip.exe would
  write the wrong machine's clipboard when SSH'd).

### Still open (separate surface)
- **Neovim yank**: nvim is on `vim.opt.clipboard = "unnamedplus"` + the built-in
  provider (the custom osc52copy override was removed earlier, see nvim log). That
  auto-provider has the SAME bug class (picks pbcopy locally → wrong clipboard on
  reattach; and may rely on tmux-forward which method 3 showed is unreliable).
  TO TEST like we tested copy-mode, then likely point nvim's clipboard provider
  at osc52copy (or an osc52-passthrough provider) so it funnels through the one
  confirmed-working path.

## 2026-03-31 — Stop macOS panes from being named reattach-to-user-namespace

### Problem
On macOS, tmux windows were being named `reattach-to-user-namespace` instead of
the interactive shell or active program.

The root cause was `tmux-sensible`, which sets:

```tmux
set-option -g default-command "reattach-to-user-namespace -l $SHELL"
```

when running on macOS and the wrapper is installed. That made new panes start
through the wrapper process, so tmux and tmux-resurrect treated
`reattach-to-user-namespace` as the pane command/window name.

### Solution

**`dot_tmux/dot_tmux.conf`**:
- Added a macOS-only post-plugin override:
  `if-shell '[ "$(uname)" = Darwin ]' 'set -gu default-command'`
- Placed it after `run '~/.tmux/plugins/tpm/tpm'` so it wins over
  `tmux-sensible`

Clipboard behavior remains intact because this setup already uses explicit copy
bindings plus `@override_copy_command '~/bin/osc52copy'`, rather than relying on
`reattach-to-user-namespace` as the pane launch wrapper.

## 2026-03-25 — Fix clipboard: context-aware osc52copy + mouse drag binding

### Problem
Local clipboard copy (both keyboard and mouse) was silently broken.

Two root causes:

1. **Wrong path**: `.tmux.conf.local` referenced `~/.local/bin/osc52copy` but
   chezmoi deploys the script to `~/bin/osc52copy`. Every copy invocation failed
   silently — no error, no clipboard write.

2. **osc52copy was SSH-only**: the script always sent an OSC52 sequence to the
   client TTY regardless of context. Locally on Wayland this had no effect
   (Kitty handled it inconsistently), whereas over SSH it correctly travelled
   through the tunnel to the terminal on mondo. Mouse highlight copy also
   lacked an explicit binding — it fell through to `set-clipboard on` + the `Ms`
   terminal override, which worked over SSH but not locally.

### Solution

**`bin/executable_osc52copy`** — rewrote to be context-aware:
- `$SSH_CONNECTION` / `$SSH_TTY` set → OSC52 to `#{client_tty}` (SSH path, unchanged)
- `$WAYLAND_DISPLAY` set + `wl-copy` available → `wl-copy` (new)
- X11 fallback → `xclip` → `xsel` (new)
- Final fallback → OSC52 to TTY

**`dot_tmux/dot_tmux.conf.local`**:
- Fixed `@override_copy_command` and `copy-mode-vi y` paths:
  `~/.local/bin/osc52copy` → `~/bin/osc52copy`
- Added `MouseDragEnd1Pane` bindings in `copy-mode-vi` and `copy-mode` tables
  so mouse highlight copy goes through `osc52copy` (and therefore `wl-copy`
  locally)
- Added `WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR` to `update-environment` so
  Wayland context propagates when attaching to existing sessions

## 2026-02-24 — Replace gpakosz with plain TPM + catppuccin

### Problem
`dot_tmux/dot_tmux.conf` was based on the gpakosz/.tmux framework but had been stripped
of its embedded shell functions (file was 201 lines; the full gpakosz config is ~600+).
This caused the following to silently fail at runtime:

- `<prefix>+` — maximize pane (called `_maximize_pane` shell fn)
- `<prefix>m` — mouse toggle (called `_toggle_mouse` shell fn)
- `<prefix>U` — urlview (called `_urlview` shell fn)
- `<prefix>F` — fpp / Facebook PathPicker (called `_fpp` shell fn)
- `run 'cut -c3- ~/.tmux.conf | sh -s _apply_configuration'` — the gpakosz theme
  engine, which read `tmux_conf_*` shell variables from `.tmux.conf.local` to build
  the status bar. Without the shell functions this line did nothing.

Additionally, plugins were declared after the `_apply_configuration` call but the
catppuccin `@plugin` line appeared after its own option lines, and `set -g
default-terminal` was duplicated (once at the top, once just before the plugin block).

### Solution
Rewrote both files to remove the gpakosz layer entirely.

**`dot_tmux/dot_tmux.conf`** (201 → 150 lines):
- Removed gpakosz heredoc trick (`# : << EOF`) and all `run 'cut -c3- ...'` calls
- Removed broken `bind +` (maximize via shell fn) — native `<prefix>z` zooms panes
- Replaced broken `bind m` with a working inline toggle:
  ```
  bind m if-shell '[ "$(tmux show -gv mouse)" = "on" ]' \
    'set -g mouse off; display "Mouse: OFF"' \
    'set -g mouse on; display "Mouse: ON"'
  ```
- Removed broken `bind U` (urlview) and `bind F` (fpp)
- Removed legacy `run -b 'tmux bind -t vi-choice ...'` and `vi-edit` shims (tmux < 2.4)
- Replaced `run -b` copy-mode bindings with direct `bind -T copy-mode-vi` (modern tmux)
- Moved `set -g mouse on` and `set -g mode-keys vi` into base config
- Fixed catppuccin option ordering (options must precede the `@plugin` declaration)
- Removed duplicate `set -g default-terminal "screen-256color"`
- `run '~/.tmux/plugins/tpm/tpm'` remains at the very end

**`dot_tmux/dot_tmux.conf.local`** (456 → 8 lines):
- Stripped all `tmux_conf_*` shell variables (gpakosz-specific, now meaningless)
- Replaced with a minimal comment header explaining the file's purpose

### Keybindings preserved
All existing keybindings were kept unchanged:
- `C-b` primary prefix, `C-Space` secondary
- `h/j/k/l` pane navigation, `H/J/K/L` pane resize
- `C-h/C-l` window navigation, `Tab` last window
- `-` split horizontal, `_` split vertical
- `<`, `>` swap panes
- `Enter` copy mode, vi copy-mode bindings
- `y` copy to OS clipboard (xsel/xclip/pbcopy/clip.exe detection)
- `b/p/P` buffer management
- `r` reload config, `e` edit .local

### Plugins configured
```
tmux-plugins/tpm
tmux-plugins/tmux-sensible
tmux-plugins/tmux-resurrect
tmux-plugins/tmux-continuum  (@continuum-restore on, save-interval 5)
catppuccin/tmux#latest        (mocha flavour, rounded window style)
```
