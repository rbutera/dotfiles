# Hunk config changes log

Hunk is an agent-focused terminal diff reviewer (`hunk` on Homebrew, v0.17.0 as
of this entry; upstream: https://github.com/modem-dev/hunk). Config is TOML.

**Config resolution (low → high precedence):**
built-in defaults → `~/.config/hunk/config.toml` (user) → `<repo>/.hunk/config.toml`
(per-repo) → CLI flags. Per-command tables (`[diff]`, `[show]`, `[patch]`,
`[difftool]`, `[pager]`) override the top-level keys for that command only.

## 2026-07-09 — Install hunk on nimbus (brew) + lancelot/WSL (npm), track in brewfile

**Problem/motivation:** Wanted hunk available on `nimbus` (macOS) and `lancelot`
(the Linux/WSL host), reachable over Tailscale.

**Fleet note (resolved a stale record):** Tailscale + `uname` confirm `nimbus` is
**macOS/arm64** and `lancelot` is **Linux/x86_64** (the WSL Ubuntu instance; the
Windows side is the separate `lancelot-win` node). The Honcho profile calling
nimbus "Linux" is wrong — the [[fleet-machines-are-macos]] memory is correct.

**What was done (over Tailscale SSH):**
- **nimbus** — `brew install hunk` → 0.17.0 (poured the `arm64_tahoe` bottle).
- **lancelot** — `npm install -g hunkdiff` (asdf node v24; reshimmed) → **0.16.0**.
  homebrew-core has no Linux bottle for hunk (only `arm64_tahoe`), so npm is the
  right channel on Linux.

**Version skew is expected and benign:** lancelot landed on 0.16.0, not 0.17.0,
because lancelot's npm enforces a publish-date **cooldown** (`before=`) — 0.17.0
was published inside the window, so `hunkdiff@0.17.0` errors `ETARGET`. Did **not**
bypass the cooldown (it's a deliberate supply-chain control). Verified 0.16.0
parses the committed `.hunk` config and renders Catppuccin Mocha (base `#1e1e2e`)
with no error, so nothing breaks when chezmoi applies the config there. lancelot
will pick up 0.17.0 on the next `npm i -g hunkdiff` once the cooldown window clears.

**Reproducibility:**
- **`raisbrewfile.tmpl`** — added `brew "hunk"` to the **darwin-only** section, so
  macOS machines (nimbus/kinto/latios) get it via `brew bundle`. Kept out of the
  common section on purpose: no Linux bottle → would trigger a source build under
  Linuxbrew.
- Linux/WSL installs (`npm i -g hunkdiff`) are not currently captured by any
  chezmoi package mechanism — noted inline in the brewfile comment. Left as a
  manual step rather than adding new (per CLAUDE.md, unreliable) run_once automation.

## 2026-07-09 — Initial config: Catppuccin Mocha + agent-focused defaults, opt-in git difftool

**Problem/motivation:** Freshly installed `hunk`. Wanted it configured with
smart defaults and a Catppuccin theme to match the rest of the terminal
(kitty / ghostty), plus a non-invasive git integration.

**Changes:**
- **`dot_config/hunk/config.toml`** (new) — deploys to `~/.config/hunk/config.toml`.
  Only overrides three keys; everything else stays at Hunk's built-in defaults
  (documented inline for discoverability):
  - `theme = "catppuccin-mocha"` — the tool ships four Catppuccin variants
    (`catppuccin-mocha`/`-macchiato`/`-frappe`/`-latte`); default was
    `github-dark-default`.
  - `agent_notes = true` — show agent-authored rationale by default (default is
    false; showing it is the point of an agent-focused reviewer).
  - `color_moved = true` — highlight moved code, mirroring `diff.colorMoved = default`
    already in `~/.gitconfig`.
- **`dot_gitconfig.tmpl`** — added a `[difftool "hunk"]` block gated on
  `{{"{{"}} lookPath "hunk" {{"}}"}}`, so it only renders on machines where the
  `hunk` binary exists (currently macOS/Homebrew only; a no-op on the Linux
  hosts). Opt-in only — invoke with `git difftool -t hunk [<rev>]`. Deliberately
  did **not** touch `core.pager`: delta stays the default pager and interactive
  diff filter. `diff.tool` was left unset so plain `git difftool` keeps its
  existing behaviour.

**Notes / verification:**
- Config keys are snake_case; booleans normalised via `normalizeBoolean2`.
  Full key set: `mode`, `vcs`, `theme`, `watch`, `exclude_untracked`,
  `line_numbers`, `wrap_lines`, `hunk_headers`, `menu_bar`, `agent_notes`,
  `copy_decorations`, `transparent_background`, `color_moved`. A `[custom_theme]`
  table (with `base`, color keys, and a `[custom_theme.syntax]` sub-table) is
  also supported if a bespoke palette is ever wanted.
- **Agent note:** for interacting with a *live* Hunk session, use the
  `hunk-review` skill and the `hunk session *` CLI — do **not** launch the
  interactive TUI (`hunk diff`/`show`) directly; that's for Rai.
- Verified end-to-end: with no `--theme` flag, `hunk diff` renders base
  `#1e1e2e` (RGB 30,30,46) = Catppuccin Mocha, proving the config file is read.
  `git config --get difftool.hunk.cmd` resolves; `core.pager` still `delta`.
