# tmux — first run setup

After a fresh chezmoi apply (new machine or reinstall), do the following before
using tmux normally.

## 1. Install TPM

TPM (Tmux Plugin Manager) must exist at `~/.tmux/plugins/tpm` before plugins can
be loaded. If it's not there:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## 2. Start tmux

```sh
tmux
```

You'll see a bare status bar — catppuccin and other plugins are not active yet.

## 3. Install plugins

Inside the tmux session:

```
<prefix> I
```

(`<prefix>` is `Ctrl-b` by default, with `Ctrl-Space` as a secondary.)

TPM will clone all plugins into `~/.tmux/plugins/`. Watch the bottom of the screen
for progress. When done it prints "TMUX environment reloaded."

## 4. Reload the config

```
<prefix> r
```

The catppuccin status bar should now appear in mocha colours.

## 5. Verify everything works

| Action | Expected result |
|--------|----------------|
| `<prefix> m` | Toggles mouse on/off with a status message |
| `<prefix> z` | Zooms current pane (native tmux) |
| `<prefix> -` | Splits pane horizontally |
| `<prefix> _` | Splits pane vertically |
| `<prefix> h/j/k/l` | Moves between panes |
| `<prefix> C-h/C-l` | Previous/next window |
| `<prefix> Enter` | Enters copy mode (vi keys) |
| `<prefix> r` | Reloads config |

## 6. Resurrect / Continuum (optional)

`tmux-continuum` auto-saves your sessions every 5 minutes and restores on startup.
After the first save you can restore manually with:

```
<prefix> Ctrl-r
```

## Clipboard integration

Copy works via `~/bin/osc52copy`, a context-aware script invoked by tmux-yank
(`@override_copy_command`) and explicit copy-mode bindings.

| Context | Method |
|---------|--------|
| Local — Wayland | `wl-copy` |
| Local — X11 | `xclip` → `xsel` → OSC52 fallback |
| Over SSH | OSC52 written directly to `#{client_tty}`, travels through the tunnel to the terminal on the local machine |

### What triggers a copy

| Action | Binding |
|--------|---------|
| `y` in copy mode | `copy-pipe-and-cancel "~/bin/osc52copy"` |
| Mouse drag release | `MouseDragEnd1Pane` → `copy-pipe-and-cancel "~/bin/osc52copy"` |
| tmux-yank (e.g. `prefix + y`) | `@override_copy_command '~/bin/osc52copy'` |

`set-clipboard on` with a `Ms` terminal override handles OSC52 passthrough for
any remaining cases (e.g. native tmux buffer operations).

### Debugging

`osc52copy` logs every invocation to `/tmp/osc52debug.log`:

```
[osc52copy] SSH_CONNECTION='' SSH_TTY='' WAYLAND_DISPLAY='wayland-0'
[osc52copy] used wl-copy
```

Check this first if copy stops working. Common culprits:

- **Wrong path**: the script must be at `~/bin/osc52copy` (deployed by chezmoi
  from `bin/executable_osc52copy`). If `.tmux.conf.local` references a different
  path the command silently fails.
- **`WAYLAND_DISPLAY` not set in tmux**: happens when attaching to a session
  started before the Wayland session. `update-environment` in `.tmux.conf.local`
  mitigates this, but detach/reattach is the reliable fix.
- **SSH detection**: relies on `$SSH_CONNECTION` or `$SSH_TTY` being set in the
  pane environment. New panes in a session started over SSH inherit this
  automatically.

## Plugin management (ongoing)

| Action | Keys |
|--------|------|
| Install new plugins | `<prefix> I` |
| Update plugins | `<prefix> U` |
| Remove unlisted plugins | `<prefix> Alt-u` |

Add new plugins to `~/.tmux/.tmux.conf` (managed via chezmoi at
`dot_tmux/dot_tmux.conf`) as `set -g @plugin '...'` lines before the
`run '~/.tmux/plugins/tpm/tpm'` line.
