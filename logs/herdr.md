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

## 2026-07-03 (pass 2) — more tmux split/pane parity + the opt-in menu applied

**Motivation.** Rai wanted the tmux split/rename/swap reflexes to *also* work in herdr
(both keymaps live side by side), plus "apply the rest" of the opt-in menu.

**tmux keys layered on (arrays, so herdr-native + tmux both fire):**
- `rename_tab` += `prefix+comma` (tmux rename-window is `prefix+,`; herdr tab ≈ window).
- `split_vertical` += `prefix+_` (tmux `_` = split right/side-by-side; herdr keeps `v`).
- `split_horizontal` stays `prefix+minus` — already == tmux `-` (split down/stacked).
- `swap_pane_down/up` += `prefix+>` / `prefix+<` (tmux `>`/`<`).
- `focus_pane_*` += `ctrl+alt+h/j/k/l` — prefix-FREE pane focus (docs' "safe" chord
  family); `prefix+h/j/k/l` retained.

**Opt-in menu applied:**
- `switch_workspace = "prefix+shift+1..9"` — direct jump to space N.
- `previous/next_workspace = prefix+shift+left/right` — cycle spaces (tmux session-hop).
- `[keys.indexed] tabs = "ctrl"` — direct `ctrl+1..9` tab jumps. CAVEAT: many terminals
  (Ghostty) don't emit distinct `ctrl+<digit>` codes; may no-op at the terminal layer.
  `prefix+1..9` is unaffected.
- `[theme] auto_switch = true` (dark=catppuccin, light=catppuccin-latte) — follow
  Ghostty's light/dark.

**Verification.** Re-applied + `herdr server reload-config` → `{"diagnostics":[],...}` and
no keybind/parse WARN in herdr-server.log — every key string (incl. the shift-punctuation
`_`/`>`/`<` and the indexed table) accepted. Terminal-layer delivery of `ctrl+<digit>` and
shift-punctuation chords is a separate concern noted above.

**Reference — what `prefix+w` does in tmux:** opens `choose-tree`, the interactive tree of
sessions+windows to pick from — the direct analogue of herdr's space/workspace picker,
which is why `prefix+w` is kept bound to `workspace_picker` alongside the new `prefix+s`.
