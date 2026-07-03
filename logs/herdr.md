# herdr changelog

Dated changelog for `dot_config/herdr/config.toml` (deployed to `~/.config/herdr/config.toml`).
herdr is a terminal workspace manager for AI coding agents — tmux-like, but with agents
as first-class, state-tracked entities. Ground truth: herdr 0.7.1. Docs: https://herdr.dev/docs.

## 2026-07-03 — tmux-reflex keybind alignment + toast/QoL pass

**Motivation.** Bring the herdr keymap closer to Rai's tmux (gpakosz/oh-my-tmux) muscle
memory, and turn on the quality-of-life bits (toasts) that were sitting at defaults.
Verified every claim against the live docs (fetched via exa) and the `herdr 0.7.1` binary
before touching config.

**Keybinds (all under `[keys]`, prefix stays `ctrl+space`).**
- `settings` moved off `prefix+s` → **`prefix+;`** (frees `prefix+s` for spaces).
- `workspace_picker` (herdr "spaces") now on **`prefix+s`** (matches tmux's `prefix+s`
  session tree), keeping native `prefix+w` as a secondary binding via an array.
- `copy_mode` entry now on **`prefix+space`**, keeping native `prefix+[` as a fallback.
  Note: the vi motions *inside* copy mode (`h/j/k/l w/b/e {/}`, `v`/Space select,
  `y`/Enter copy, `q`/Esc leave) are HARDWIRED by herdr — only the entry key is bindable.
- **Bug fix:** `next_agent`/`previous_agent` were on `prefix+shift+j`/`k`, which collide
  with herdr's `swap_pane_down`/`swap_pane_up` defaults. Moved agent nav to
  `prefix+shift+down`/`prefix+shift+up` (unbound by default). `focus_agent` unchanged.

**QoL.**
- `[ui] prompt_new_tab_name = false` — instant tabs, matching tmux `automatic-rename off`.
- `[ui.toast] delay_seconds = 1` — documented the flap-debounce knob explicitly.
- `[ui.toast.clipboard] enabled = true, position = "bottom-center"` — "copied to
  clipboard" confirmation toast. Valuable here because copies leave over OSC 52 (incl.
  SSH) and are otherwise invisible; the toast is proof the yank landed.

**Verification.** `chezmoi apply ~/.config/herdr/config.toml` (no 1Password — file has no
`onepasswordRead`), then `herdr server reload-config` returned
`{"diagnostics":[],"status":"applied"}`. Empty diagnostics = every binding parsed clean,
including `prefix+;` and `prefix+space`.

**Not yet applied (offered as opt-in).** Direct prefix-free `ctrl+alt+h/j/k/l` pane-focus
chords (docs' recommended "safe" modifier family); `theme.auto_switch` light/dark
catppuccin; `switch_workspace = "prefix+shift+1..9"`; `previous/next_workspace` cycling;
`[keys.indexed] tabs = "ctrl"` for direct `ctrl+1..9` tab jumps.
