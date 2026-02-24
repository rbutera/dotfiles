# tmux config changes log

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
