# shell config changes log

## 2026-07-25 — One GitHub token, not three: fix gh + the Codex GitHub MCP server

### Problem

Three different GitHub tokens were in play, and the two that tools actually reached for
were the two that do not work against `easyjet-dev`:

| Token | Source | easyjet-dev |
|-------|--------|-------------|
| `op://Private/github gh PAT` | `$GITHUB_TOKEN` and friends, via `dot_config/zsh/github.zsh.tmpl` | works, has the SAML SSO grant |
| `op://dev/github_auth` | gh's own `hosts.yml`, via `dot_config/gh/private_hosts.yml.tmpl` | 403, no SSO grant |
| `op://Private/github llm personal access token` | `$GITHUB_LLM_PAT`, and the Codex GitHub MCP server | 404, fine-grained PAT scoped elsewhere |

This was invisible day to day because `$GITHUB_TOKEN` is exported into every interactive
shell and takes precedence over `hosts.yml`, so `gh` on the command line always picked the
working token. Anything that did not inherit the interactive shell env fell through to the
broken one: launchd jobs, MCP servers, subagents. The Codex GitHub MCP server was worse
again, since it names its token explicitly and named the fine-grained PAT, so it had been
404ing on every easyjet-dev repo.

This is the other half of the 2026-04-24 entry below. That fix repointed `GITHUB_TOKEN` at
the right 1Password item but left `hosts.yml` and the MCP server on their old ones.

### Changes

**`dot_config/gh/private_hosts.yml.tmpl`** - now reads `op://Private/github gh PAT`, the
same item as `GITHUB_TOKEN`, using the same single-fetch `onepasswordDetailsFields`
pattern as `github.zsh.tmpl`. gh now behaves identically whether or not `GITHUB_TOKEN` is
in the environment. `op://dev/github_auth` is no longer referenced anywhere.

**`dot_codex/modify_private_config.toml`** - `mcp_servers.github.bearer_token_env_var`
changed from `GITHUB_LLM_PAT` to `GITHUB_TOKEN`, with a comment recording why.

### The general shape

One credential, one 1Password item, referenced by name everywhere. Two items holding two
different tokens for the same purpose will always drift, and the drift stays hidden for as
long as the precedence order happens to favour the good one.

### Verifying

```sh
# both must print the same hash
printf '%s' "$GITHUB_TOKEN" | shasum -a 256 | cut -c1-12
env -u GITHUB_TOKEN -u GH_TOKEN gh auth token | shasum -a 256 | cut -c1-12

# must succeed with the env var out of the way
env -u GITHUB_TOKEN -u GH_TOKEN gh api repos/easyjet-dev/eja-orangeai-checklists --jq .full_name
```

## 2026-07-14 — zshrc: adopt the bun completions block into the template

### Problem

`/chezmoi-sync` showed `~/.zshrc` drifted: the deployed file had a bun
completions block the template didn't, while the template had a grok installer
block the deployed file didn't. Both were appended by their respective
installers on different machines/runs — so neither side was "wrong", and a plain
apply in either direction would have destroyed one of them.

### What changed

- **`dot_zshrc.tmpl`**: added the bun completions block alongside the existing
  grok block, rewritten to use `$HOME` instead of the installer's hardcoded
  `/Users/rai/.bun/_bun` (this file also deploys to Linux). The `[ -s ... ]`
  guard keeps it inert where bun isn't installed.

Applied; `zsh -n ~/.zshrc` parses clean, both blocks present, zero residual drift.

## 2026-06-19 — flaude: add --dangerously-skip-permissions

### Problem
The `flaude`/`florence` function in `dot_aliases.tmpl` launched Claude Code without the
permission-bypass flag, so the Florence session prompted for permissions on every action.

### Solution
**`dot_aliases.tmpl`** — added `--dangerously-skip-permissions` to both `command claude`
invocations in `flaude()` (the brain-found branch and the plain-fallback branch).

## 2026-04-24 — Fix GITHUB_TOKEN source and add SonarQube env vars

### Problem
`GITHUB_TOKEN` was reading from `op://Private/github llm personal access token/credential` — the same item as `GITHUB_LLM_PAT`. This is a restricted-scope LLM-specific token, not a general-purpose `gh` CLI token. Tools expecting a standard GitHub PAT (e.g. `gh`, MCP servers) got the wrong token.

Also needed SonarQube/SonarCloud credentials exported for the EasyJet work profile so SonarQube tooling works in that context.

### Changes

**`dot_zshenv.tmpl`**:
- Changed `GITHUB_TOKEN` to read from `op://Private/github gh PAT/credential` (matches `GITHUB_API_PERSONAL_ACCESS_TOKEN`)
- Added `SONARQUBE_TOKEN`, `SONARQUBE_ORG` (`easyjet-dev`), and `SONARQUBE_URL` (`https://sonarcloud.io`) under the work host group block

## 2026-04-23 — Make ARK_WORKSPACE conditional on work/personal machine

### Problem
`ARK_WORKSPACE` was hardcoded to `$HOME/navi` for all machines. Work machines should use `$HOME/focused` instead.

### Changes

**`dot_zshenv.tmpl`**:
- Made `ARK_WORKSPACE` conditional using `host_groups.work`: work machines (currently `latios`) get `$HOME/focused`, all others (including `nimbus`) keep `$HOME/navi`.

## 2026-04-16 — Fix Atlassian env var names for mcp-atlassian

### Problem
Installed `mcp-atlassian` (sooperset/mcp-atlassian) as an MCP server in Claude Code for authenticated JIRA/Confluence API access. The server expects `JIRA_API_TOKEN` and `CONFLUENCE_API_TOKEN`, but the env vars were named `JIRA_API_KEY` and `CONFLUENCE_API_KEY`. Confluence URL also needed `/wiki` suffix.

### Changes

**`dot_zshenv.tmpl`**:
- Renamed `JIRA_API_KEY` to `JIRA_API_TOKEN`
- Renamed `CONFLUENCE_API_KEY` to `CONFLUENCE_API_TOKEN`
- Appended `/wiki` to `CONFLUENCE_URL` (Confluence API requires it)

## 2026-04-16 — Fix tmux_auto and add flaude alias

### Problem
`tmux_auto` always failed with "can't find session 0" when sessions existed but weren't named `0` (e.g. after killing session 0 and creating new ones, or when sessions have custom names). The function hardcoded `-t 0`.

Also needed a quick alias to open Claude Code in the `~/focused` directory.

### Changes

**`dot_aliases.tmpl`**:
- `tmux_auto`: removed `-t 0` from `tmux attach-session`. Bare `tmux attach` connects to the most recently used session regardless of name.
- Added `alias flaude='cd ~/focused && claude'`.

## 2026-04-12 — Export `ARK_WORKSPACE` so `ark attach`/`ark run` work from anywhere

### Problem

`ark` CLI commands (`ark attach`, `ark run`, etc.) resolve the workspace root from `process.cwd()`, which means they only work when invoked from inside `~/navi` (or another workspace dir). Running them from anywhere else fails to find the workspace.

### Solution

Earlier today, lumiere commit `d55035f` (`feat(ark): add resolveWorkspaceRoot with ARK_WORKSPACE env fallback`) added a new `resolveWorkspaceRoot()` helper in `apps/ark/src/config.ts` that falls back to `$ARK_WORKSPACE` when no explicit path is passed, before finally defaulting to `cwd`.

Added `export ARK_WORKSPACE="$HOME/navi"` to `dot_zshenv.tmpl` under a new `── Ark ──` section so every shell picks it up. Now `ark attach` / `ark run` work from any directory.

### Verification

After `chezmoi apply` and a shell reload, `cd /tmp && ark attach` should target the `~/navi` workspace instead of failing.
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
