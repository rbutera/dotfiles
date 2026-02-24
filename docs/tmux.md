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

## Plugin management (ongoing)

| Action | Keys |
|--------|------|
| Install new plugins | `<prefix> I` |
| Update plugins | `<prefix> U` |
| Remove unlisted plugins | `<prefix> Alt-u` |

Add new plugins to `~/.tmux/.tmux.conf` (managed via chezmoi at
`dot_tmux/dot_tmux.conf`) as `set -g @plugin '...'` lines before the
`run '~/.tmux/plugins/tpm/tpm'` line.
