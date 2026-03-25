# Plan: merge pbcopy + osc52copy into a single clipboard script

## Background

There are currently two clipboard scripts:

| Script | Primary use | SSH handling |
|--------|-------------|--------------|
| `~/bin/pbcopy` | General-purpose — shell aliases, scripts, outside tmux | `printf OSC52` to **stdout** |
| `~/bin/osc52copy` | tmux-internal — `copy-pipe-and-cancel`, `@override_copy_command` | `printf OSC52` to **`#{client_tty}`** (tmux-specific) |

The goal is one script (`~/bin/pbcopy`) that handles every context correctly, so
`osc52copy` can be retired and `.tmux.conf.local` updated to reference `pbcopy`.

---

## Decision: keep the name `pbcopy`

`pbcopy` is the name used by macOS natively, making it the natural cross-platform
alias. It is also already referenced in aliases (`c`, etc.) and muscle memory.
`osc52copy` becomes an alias or symlink for backwards compatibility if needed, or
is simply removed once `.tmux.conf.local` is updated.

---

## Key behavioural differences to resolve

### 1. SSH + tmux vs SSH outside tmux

The two scripts take different approaches to SSH:

- **`pbcopy`**: writes `OSC52` to **stdout**. Works correctly when called from a
  plain shell (the terminal reads stdout and interprets the sequence). Fails
  silently inside `copy-pipe-and-cancel` because stdout is not the terminal TTY.

- **`osc52copy`**: writes `OSC52` directly to **`#{client_tty}`** via
  `tmux display-message`. Works correctly inside `copy-pipe-and-cancel`. Outside
  tmux `tmux display-message` returns empty and it falls back to `/dev/tty`,
  which works in most terminals.

**Resolution**: detect whether we are inside tmux (`$TMUX` is set) and use the
appropriate output target.

```
SSH branch:
  if inside tmux → write OSC52 to #{client_tty}   (osc52copy approach)
  else           → write OSC52 to stdout            (pbcopy approach)
```

### 2. `SSH_TTY` vs `SSH_CONNECTION`

`pbcopy` checks only `$SSH_CONNECTION`. `osc52copy` checks both `$SSH_CONNECTION`
and `$SSH_TTY`. Use both for robustness.

### 3. `printf '%s'` vs `echo -n`

`osc52copy` uses `printf '%s'` which is more portable (avoids `echo -n`
portability issues with some shells). Use `printf '%s'` throughout.

### 4. `#!/bin/bash` vs `#!/usr/bin/env bash`

`pbcopy` uses `#!/bin/bash`; `osc52copy` uses `#!/usr/bin/env bash`. Prefer
`#!/usr/bin/env bash` for portability across macOS and Linux (Homebrew bash).

---

## Merged execution order

```
1. SSH (SSH_CONNECTION or SSH_TTY set)
   └─ inside tmux ($TMUX set) → OSC52 to #{client_tty}
   └─ outside tmux            → OSC52 to stdout

2. macOS (/usr/bin/pbcopy exists and is executable)
   └─ /usr/bin/pbcopy

3. WSL2 (clip.exe available)
   └─ clip.exe

4. Wayland (WAYLAND_DISPLAY set + wl-copy available)
   └─ wl-copy

5. X11 — xclip
6. X11 — xsel

7. Fallback
   └─ inside tmux → OSC52 to #{client_tty}
   └─ outside tmux → OSC52 to stdout
```

---

## Implementation notes

- Keep the debug log (`/tmp/osc52debug.log`) from `osc52copy` — useful for
  diagnosing clipboard failures in tmux context.
- `osc52_to_tty()` helper from `osc52copy` can be reused as-is.
- After merging, update `.tmux.conf.local`:
  - `@override_copy_command '~/bin/pbcopy'`
  - `copy-pipe-and-cancel "~/bin/pbcopy"` (all three bindings: `y`,
    `MouseDragEnd1Pane` × 2)
- Delete `bin/executable_osc52copy` from the chezmoi source.
- Update the `c` alias — no change needed, it already calls `pbcopy`.

---

## Files changed

| File | Change |
|------|--------|
| `bin/executable_pbcopy` | Rewrite with merged logic |
| `bin/executable_osc52copy` | Delete |
| `dot_tmux/dot_tmux.conf.local` | Update all 3 references to point at `pbcopy` |
| `docs/tmux.md` | Update clipboard section (script name, no behaviour change) |
