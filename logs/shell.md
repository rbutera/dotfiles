# shell config changes log

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
