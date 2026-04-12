# shell config changes log

## 2026-04-12 — Adopt Vite+ in system-first mode (asdf keeps owning node)

### Problem
Installed [Vite+](https://viteplus.dev) (`~/.vite-plus/`) to try the toolchain. The installer prompted "would you like Vite+ to manage your Node.js versions?" and the answer was an unintentional yes, which:

1. Created shadow shims at `~/.vite-plus/bin/{node,npm,npx}` → all symlinked to `vp`. Because `~/.vite-plus/env` prepends `~/.vite-plus/bin` to `PATH`, any new shell would resolve `node`/`npm` to vp's wrapper instead of the asdf shims.
2. Appended an unconditional `. "$HOME/.vite-plus/env"` block to **both** `~/.zshrc` and `~/.zshenv` (drift vs chezmoi source — the zshrc one showed in `chezmoi diff`; the zshenv one was hidden behind the 1Password prompt).

Goal: keep Vite+ installed for project tooling (`vp dev`, `vp build`, etc.) but continue using asdf as the node version manager.

### Solution

1. **`vp env off`** — flips the shims into "system-first" mode. They still exist, but vp's wrapper now defers to whatever non-vp `node` it finds on PATH (asdf's shim) and only falls back to vp's bundled node if nothing else is available. Verified with `vp env doctor`:
   ```
   Node.js mode      system-first
   System Node.js    /Users/rai/.asdf/shims/node
   ```
   No separate config file — the mode IS the shim behavior.

2. **`dot_zshrc.tmpl`** — added the Vite+ source block at the end (after SDKMAN, matching where the installer placed it), but wrapped in `[[ -s "$HOME/.vite-plus/env" ]] && ...` so other machines without Vite+ installed don't error on shell startup. Applied with `chezmoi apply --force ~/.zshrc` (force needed because the deployed file had drifted from what chezmoi last wrote).

3. **`dot_zshenv.tmpl`** — added the same conditional block at the end (after the Rust/cargo block). Vite+ installs to `.zshenv` as well as `.zshrc` so that IDE / non-interactive shells also get vp on PATH; matching that behavior in the template avoids future drift on every machine where Vite+ is installed. Not applied this session because `dot_zshenv.tmpl` uses `onepasswordRead` and there was no active op session — will reconcile on the next `chezmoi apply` after signin.

### Notes for future me

- To fully remove Vite+: `~/.vite-plus/bin/vp implode -y`, then strip the conditional blocks from `dot_zshrc.tmpl` and `dot_zshenv.tmpl`.
- `vp env doctor` warns about asdf as a "conflict" — this is informational only; system-first mode is exactly what makes the two coexist.
- `vp env which node` reports vp's bundled `js_runtime/node/24.14.1` because that's the *managed* fallback. The actually-resolved binary in shells is still asdf's, as confirmed by `which node`.

## 2026-04-11 — Consolidate env vars and PATH into zshenv

### Problem
Environment variables and PATH entries were scattered across `dot_zshenv.tmpl`, `dot_zprofile.tmpl`, and `dot_zshrc.tmpl` with duplicates and a LANG conflict (`en_US.UTF-8` in zprofile vs `en_GB.UTF-8` in zshrc). Non-interactive shells and scripts couldn't see vars like EDITOR, GOPATH, XDG_CONFIG_HOME, or tool PATHs because those were only set in login-shell (zprofile) or interactive-shell (zshrc) files.

### Changes

**`dot_zshenv.tmpl`** — added 21 env vars and 10 PATH entries, organized into sections:
- **Locale**: LANG=en_GB.UTF-8 (resolved conflict, user confirmed en_GB)
- **Editors**: EDITOR, VISUAL, SUDO_EDITOR, PAGER, MANPAGER (from zprofile)
- **Paths**: bob-nvim, opencode, ~/.local/bin, ~/bin, asdf shims, Go, pnpm (from zprofile+zshrc)
- **Platform paths**: DOCKER_HOST (macOS), BROWSER (macOS/WSL), Windows System32 PATH (WSL), ccache (Arch)
- **Tool config**: LESS, FZF_DEFAULT_OPTS, CHEZMOI_DIR, SDKMAN_DIR, SSH_ASKPASS, GIT_TERMINAL_PROMPT (from zprofile+zshrc)
- **SSH overrides**: OP_BIOMETRIC_UNLOCK_ENABLED, OP_ACCOUNT (from zshrc)
- **Platform-specific**: COLORTERM, XDG_CONFIG_HOME (Linux), MOZ_ENABLE_WAYLAND, XDG_DATA_DIRS (Arch)

**`dot_zprofile.tmpl`** — removed all items moved to zshenv. Kept: Homebrew shellenv (eval, runtime-dependent), Tailscale PATH check, typeset -gU dedup, nodenv/pyenv/poetry conditional checks, LESSOPEN, fzf.zsh source, setopt NO_NOMATCH, OrbStack init. Also removed redundant `PATH="$HOME/.cargo/bin"` (already handled by `.cargo/env` in zshenv).

**`dot_zshrc.tmpl`** — removed all items moved to zshenv. Kept: WSL PATH filter (expensive pipeline, interactive-only), isomorphic-copy PATH (conditional dir check), SDKMAN init sourcing, all interactive setup. Removed duplicate EDITOR/VISUAL, bob-nvim PATH, pnpm PATH (macOS).

### Items deliberately NOT moved (runtime-dependent)
- Homebrew `eval "$(brew shellenv)"` — runs subshell, too heavy for zshenv
- Tailscale, nodenv, pyenv, poetry PATH checks — filesystem probes on every invocation
- LESSOPEN — uses `$#commands` zsh expansion
- WSL PATH filter — expensive pipeline, interactive fix only

## 2026-04-04 — Remove miru() alias

### Changes

- `dot_aliases.tmpl`: removed `miru()` function (mpv loop-playlist helper for video folders). No longer needed.

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
