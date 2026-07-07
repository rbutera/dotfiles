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

## 2026-07-03 (pass 3) — scroll speed knob (perf triage)

**Symptom.** Rai: scrolling feels slow; interface laggy after a long multi-day session.

**Triage (local, verified).** herdr-server up 2d1h at ~24-31MB RSS (no leak), all 7 panes
idle zsh at 0% CPU, yet the server burns ~8% CPU idle — i.e. herdr's own render/event
loop, not a chatty pane. On 0.7.1 = latest stable (no update lever). All perf knobs were
at defaults.

**Change.** `[ui] mouse_scroll_lines = 5` (was default 3) — faster viewport scroll.

**Not changed (offered).** `redraw_on_focus_gained=false` (less redraw churn on focus,
trade-off: rare surface corruption until next redraw); lower `scrollback_limit_bytes`
(default 10MB/pane) to shrink the render walk on long sessions. Real lever for cumulative
lag: restart the server (`herdr server stop` then `herdr`, or `herdr update --handoff`) —
safe because panes restore + `resume_agents_on_restore=true`. Pre-1.0 render-loop overhead
is a known rough edge at this stage.

## 2026-07-07 — agent-switch on prefix+tab, pane-close guard, + [keys.indexed] drift reconciled

**Motivation.** Rai wanted (1) a good key to switch between agents, and (2) a confirmation
before closing a pane because he kept nuking panes by accident.

**Agent switching → prefix+tab / prefix+shift+tab.** `prefix+tab` and `prefix+shift+tab`
were herdr's `cycle_pane_next`/`cycle_pane_previous` defaults. Repointed them at agent nav:
- `next_agent = "prefix+tab"`, `previous_agent = "prefix+shift+tab"`. With
  `agent_panel_sort = "priority"`, tab walks the attention queue top-down (next = who needs
  you most) — the ADHD-routing win, on a key that's actually memorable.
- Pane cycling relocated off tab to `cycle_pane_next = "prefix+o"` /
  `cycle_pane_previous = "prefix+shift+o"` (tmux's "other pane" reflex) to avoid the
  same key-collision class as the old shift+j/k bug. Directional `prefix+hjkl` stays the
  primary pane nav; cycling is the secondary motion.
- This REPLACED the previous parking of agent nav on `prefix+shift+down/up`.

**Pane-close guard → prefix+shift+x.** herdr has NO per-pane close confirmation:
`confirm_close` guards WORKSPACES only (verified against 0.7.1 docs, herdr.dev/docs/
configuration). Since there's no confirm flag, mitigated by moving `close_pane` off the
fat-finger-prone bare `prefix+x` to `prefix+shift+x` ("shift = more destructive", matches
swap_pane on shift+j/k). A reflexive single `prefix+x` tap now no-ops instead of killing a
pane. FOLLOW-UP: worth a feature request to herdr for a real `confirm_close_pane` — Rai
clearly wants tmux's `kill-pane? (y/n)` behavior.

**Drift reconciled — [keys.indexed] removal (reverses pass-2 decision).** Found the
deployed `~/.config/herdr/config.toml` had drifted from source: the `[keys.indexed] tabs =
"ctrl"` table added in pass 2 had been removed on the machine and replaced with a warning
comment, never synced back. Pulled that fix into source. WHY it was removed: setting
`[keys.indexed] tabs = "ctrl"` does NOT *add* a ctrl+1..9 shortcut — herdr treats a legacy
`[keys.indexed]` entry as user config that DISPLACES the modern `switch_tab = prefix+1..9`
default, silently removing it and rebinding tabs to ctrl+1..9 only. And ctrl+<digit> is
un-typeable here (ctrl+2 emits NUL == the ctrl+space prefix), so the net result was ZERO
working tab-switch keys. Leaving `switch_tab` unset keeps herdr's default `prefix+1..9`.
This supersedes the pass-2 log entry that recommended the indexed table.

**Verification.** `chezmoi apply --force ~/.config/herdr/config.toml` (no 1Password — file
has no onepasswordRead; `--force` needed because the deployed file was hand-edited so
chezmoi's state hash mismatched), then `herdr server reload-config` returned
`{"diagnostics":[],"status":"applied"}`. Empty diagnostics = every binding parsed clean,
including `prefix+tab`, `prefix+o`, and `prefix+shift+x`.

## 2026-07-07 (pass 4) — pane-close confirmation via a plugin (prefix+x)

**Motivation.** Core herdr has no per-pane close confirmation (the core PR for it,
ogulcancelik/herdr#1129, was auto-closed by the first-time-contributor gate). herdr
discussion #884 suggested a plugin instead. Built one.

**Plugin.** `rbutera.confirm-close-pane` — new public repo
https://github.com/rbutera/herdr-confirm-close-pane (zero-dep POSIX sh). Flow: prefix+x →
`plugin_action` `confirm` (headless, captures the focused pane from HERDR_PANE_ID) → opens
an overlay pane running a `[y] close / anything-else keep` prompt → on `y` runs
`herdr pane close <that pane>`. Plugin v1 has no native modal, so the confirm is an overlay
prompt. Target is handed to the overlay per-invocation via `plugin pane open --env
HCCP_TARGET_PANE=<id>` (no shared state file → no wrong-pane race). Only an explicit y/Y
closes; Enter/Esc/EOF/any other key keep (default-to-keep on ambiguity). Built with an
OpenSpec proposal + dual Opus/Codex review (two rounds: first round FAILed on a wrong-pane
race + an EOF-defaults-to-close bug; both fixed and re-reviewed PASS). shellcheck clean,
13/13 unit + 2/2 live (verified against real herdr 0.7.1 on kinto).

**Keybind (`dot_config/herdr/config.toml`).** Added a second `[[keys.command]]`:
`prefix+x` → `type=plugin_action` → `rbutera.confirm-close-pane.confirm`. Composes with the
pass-1 change: `prefix+x` now = guarded close (asks first), `prefix+shift+x` (`close_pane`)
= immediate close. REQUIRES the plugin installed on the machine or reload-config errors on
the unknown action — install with `herdr plugin install rbutera/herdr-confirm-close-pane
--yes`.

**Applied on kinto.** Plugin installed from GitHub, `chezmoi apply --force
~/.config/herdr/config.toml`, `herdr server reload-config` → `{"diagnostics":[]}` (the
plugin_action binding parsed clean). NOTE: this machine (kinto) is macOS/Apple Silicon, not
Linux as the old fleet notes said; nimbus is also macOS.

**nimbus: NOT done.** herdr is not installed on nimbus (only the chezmoi-deployed config is
present), so the plugin has nothing to attach to there. Left for Rai to decide whether to
`brew install herdr` on nimbus first. The keybind is in the shared chezmoi config, so once
herdr + the plugin exist on nimbus, `chezmoi apply ~/.config/herdr/config.toml` + install
the plugin + reload-config finishes it.
