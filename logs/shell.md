# shell config changes log

## 2026-03-28 — Fix ~5min `ls ~` hang caused by unreachable SSHFS automount

### Problem
`la ~` / `ls ~` (aliased to eza) hung for ~5 minutes on `mondo`. The `/home/rai/lugia` directory was an SSHFS automount (`fuse.sshfs` via `x-systemd.automount` in fstab) pointing to `rai@navi:/home/rai`. The remote host `navi` was unreachable (spun down), so every `stat()` call on `~/lugia` blocked until the SSH connection timed out.

### Solution

1. **Moved mount out of `~`**: changed mount point from `/home/rai/lugia` to `/mnt/nimbus` in `/etc/fstab` so directory listings of `~` no longer trigger the automount.
2. **Updated remote host**: `rai@navi` → `rai@nimbus` (lugia/navi decommissioned, replaced by nimbus).
3. **Added `x-systemd.mount-timeout=10s`** to fstab options so future unreachable states fail fast instead of hanging for minutes.
4. **Updated SSH config** (`dot_ssh/config.tmpl`): renamed `Host lugia` → `Host nimbus`.
5. Stopped old automount, removed empty `~/lugia` directory, reloaded systemd.

## 2026-03-28 — Fix ~47s shell startup and slow `ll` in home directory

### Problem
Opening new terminal windows took ~47 seconds, and `cd` / `ls` appeared to lock up the terminal. Affected all Linux machines sharing chezmoi-managed dotfiles.

Two root causes:

1. **Dual prompt frameworks**: Prezto was configured to load the Spaceship prompt theme (`zstyle ':prezto:module:prompt' theme 'spaceship'`) while Starship was also initialized via `eval "$(starship init zsh)"` in `.zshrc`. Spaceship's `spaceship_exec_vcs_info_precmd_hook` ran a full VCS scan on every prompt render. In `~` (which contains many large nested git repos), this took ~47 seconds per prompt.

2. **`eza --git` in non-repo directories**: The `ll` alias included `--git`, causing eza to recursively scan all subdirectories for git status. In `~` this took ~55 seconds.

### Solution

**`dot_zpreztorc.tmpl`** — changed Prezto prompt theme from `'spaceship'` to `'off'`, since Starship is the actual prompt.

**`dot_aliases.tmpl`** — removed `--git` from the `ll` alias (`ls -l` instead of `ls --git -l`).

Result: prompt render in `~` dropped from ~47s to ~0.09s.
