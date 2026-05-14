# Windows port

Notes on bringing the Windows arm of these dotfiles to life. Targets PowerShell 7
on Lancelot (rai's personal Windows 11 box). zsh / Linux files stay untouched on
this OS via `.chezmoiignore`.

## 2026-05-01 — Initial Windows arm

**Why:** Lancelot is a freshly provisioned Windows 11 box. Same dotfiles repo
should drive it without forking, the way macOS / Arch / Ubuntu / WSL do today.

**What changed:**

- `.chezmoiignore` — added a `{{ if eq .chezmoi.os "windows" }}` block listing
  every Unix-only target (zsh family, prezto, tmux, kitty/ghostty/warp/zellij,
  hypr/kanata/karabiner, paru/pacman, brewfile, the existing `run_once_*.sh*`
  scripts) plus the four bash-only `modify_*` scripts that don't execute on
  Windows (`.claude.json`, `.claude/settings*.json`, `.codex/config.toml`).
  Patterns match against **target** paths (post `dot_` → `.` rewrite), not
  source paths — the gitignore-style syntax fooled me on the first attempt.
- Inverse block added so Windows-only sources (`Documents/`, the new
  `run_onchange_*` scripts) are ignored on non-Windows machines.
- New: `Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`. Mirrors
  the subset of `dot_zshenv.tmpl` + `dot_aliases.tmpl` that translates
  cleanly: starship/zoxide/mise/PSFzf init, vi-mode PSReadLine, eza/bat
  aliases, git/chezmoi shortcuts, claude/codex wrappers with the
  `--dangerously-*` defaults. Secrets rendered via `onepasswordRead` — same
  pattern as `dot_zshenv.tmpl`, so applying this template on Windows
  requires a live 1Password CLI session just like applying `.zshenv` does
  on Linux/macOS.
- New: `run_onchange_install-windows-packages.ps1.tmpl`. Idempotent winget
  installer — checks `winget list --id X --exact` before installing.
  Packages: PowerToys, Neovim, Zed, uutils.coreutils, mise, starship,
  zoxide, fzf, ripgrep, fd, bat, eza, delta, jq, yq, lazygit, gh, Clink.
  Also installs scoop (via the official one-liner), the `nerd-fonts` bucket,
  and JetBrainsMono Nerd Font (winget Nerd Font coverage is patchy). Then
  PSGallery modules: PSReadLine, PSFzf.
- New: `run_onchange_setup-clink-windows.ps1.tmpl`. Wires up Clink + Starship
  as cmd.exe's prompt via `%LocalAppData%\clink\starship.lua` and runs
  `clink autorun install`. PATH refreshed from the registry at the top so
  it works in the same `chezmoi apply` that just installed Clink.

**Local config:** `~/.config/chezmoi/chezmoi.toml` was hand-written rather
than going through `chezmoi init` because the config template's `promptString`
prompts can't be answered from a non-TTY automation. Defaults from
`.chezmoi.toml.tmpl` were used (email = `rai@rbutera.com`, name = `Rai
Butera`). chezmoi will warn `config file template has changed, run chezmoi
init to regenerate config file` until `.chezmoi.toml.tmpl` is updated to
emit a Windows-aware `[cd] command` (`pwsh` instead of `zsh`). Non-blocking.

**Run-once vs run-onchange:** Initially used `run_once_` for the bootstrap
scripts. Switched to `run_onchange_` so future content edits trigger
re-runs automatically — tracking by content hash. Both scripts are
idempotent so re-running on every change is cheap.

**Known gaps / follow-ups:**

- `dot_claude/modify_settings.json`, `modify_settings.local.json`,
  `modify_dot_claude.json.tmpl`, `dot_codex/modify_private_config.toml` are
  bash-based JSON/TOML mutators. Ignored on Windows for now. Eventually
  port these to PowerShell or use chezmoi's built-in JSON merge instead of
  shelling out to bash.
- No Neovim config in this repo (installed via bob on Linux/macOS, no
  `.config/nvim/` source). Windows nvim is on its own until a config gets
  added.
- `dot_aider.conf.yml.tmpl`, `dot_env.tmpl`, `dot_chronicler.json.tmpl`,
  `dot_ssh/`, `dot_config/{aichat,gh,private_github-copilot}/` are ignored
  on Windows for now (mostly because they pull from 1Password and aren't
  needed on a fresh Windows install yet). Re-enable selectively when
  needed.
- Profile cold-start time is ~7s — `mise activate pwsh` and the module
  scans (`Get-Module -ListAvailable`) are the prime suspects. Worth caching
  `mise activate` output to a file.
- First Zed install attempt used `Zed-Industries.Zed` which winget rejects;
  fixed in revision 2 to `ZedIndustries.Zed` (no hyphen).
- First Clink config attempt failed with `clink not yet on PATH` because
  the script ran in the same apply as Clink's installer and didn't refresh
  PATH; fixed in revision 2 by reading PATH from the registry at script
  start.
- PSReadLine `HistorySearchBackward` throws a null-ref when there's no
  matching history; replaced the raw key bindings with scriptblocks that
  fall back to `PreviousHistory` / `NextHistory` on empty buffer.

## 2026-05-01 — modify_ scripts cross-platform, nvim port, Windows Terminal sync

**Why:** windows machine should benefit from edits to managed config files
(claude/codex settings, nvim config, terminal config) just like the unix
machines do. The first windows apply ignored the four `modify_*` scripts and
had no nvim config or terminal sync.

**modify_ scripts now run on Windows:**

- Shebangs changed from `#!/bin/bash` and `#!/usr/bin/python3` to
  `#!/usr/bin/env bash` and `#!/usr/bin/env python3` so chezmoi's shebang
  parser can find the interpreters via PATH on every platform.
- `run_onchange_install-windows-packages.ps1.tmpl` (revision 3) now
  installs `Python.Python.3.13`, `pip --user install`s `tomli` and
  `tomli_w` (needed by `dot_codex/modify_private_config.toml`),
  prepends `C:\Program Files\Git\bin` to user PATH so `bash` resolves to
  Git's real bash instead of the WSL stub at
  `%LocalAppData%\Microsoft\WindowsApps\bash.exe`, prepends `~/bin` to
  user PATH, and writes `~/bin/python3.cmd` (`@py -3 %*`) since the
  Windows Python installer ships `python.exe` and `py.exe` but no
  `python3.exe`.
- The four `modify_*` targets (`.claude.json`, `.claude/settings.json`,
  `.claude/settings.local.json`, `.codex/config.toml`) were removed from
  the Windows ignore block.
- **Side effect:** typing `bash` in PowerShell now launches Git Bash
  rather than the WSL stub. Use `wsl` (or open a WSL tab in Windows
  Terminal) to reach the WSL distribution.

**Neovim:**

- New `run_onchange_install-nvim-windows.ps1.tmpl`. Clones
  `https://github.com/rbutera/astronvim_config.git` to
  `%LocalAppData%\nvim` (Neovim's Windows-native config dir; XDG isn't
  required) and runs `nvim --headless '+Lazy! sync' '+qa'` to install
  plugins. Idempotent: skips clone if directory already exists.
- HTTPS rather than SSH because dot_ssh/ is ignored on Windows and the
  1Password SSH key flow isn't wired up here yet. The repo is public so
  unauth clone is fine.
- No bob (the rust-based neovim version manager) on Windows — winget's
  `Neovim.Neovim` already covers it. Bob is overkill when winget can
  upgrade nvim with one command.

**Windows Terminal:**

- New source path
  `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json.tmpl`,
  ignored on non-Windows.
- Started from the existing config (Catppuccin Mocha + JetBrainsMonoNL
  Nerd Font on the Ubuntu profile only). Moved colorScheme, font,
  opacity, padding, useAcrylic, scrollbarState into the `defaults`
  block so PS7 and cmd inherit the same look.
- `defaultProfile` switched from WSL Ubuntu to PowerShell 7 so opening
  Windows Terminal lands in pwsh by default — matches how this machine
  is set up. Ubuntu still in `list` and accessible via the dropdown.
- Added `copyOnSelect: true` (zsh-like), `intenseTextStyle: "all"`,
  `antialiasingMode: "grayscale"`, plus pane split/move keybindings.
- WT watches the file and auto-reloads, so applying these takes effect
  without a restart.

**Known gaps / follow-ups:**

- The chezmoi config template warning (`config file template has changed,
  run chezmoi init to regenerate config file`) is still present; should
  be fixed by updating `.chezmoi.toml.tmpl` to emit a Windows-aware
  `[cd] command` (`pwsh` instead of `zsh`) so a regenerated local config
  matches.
- Nvim install script is currently fire-and-forget on first run; doesn't
  pull updates on subsequent runs. Could add a `git -C $nvimDir pull
  --ff-only` if there are no local changes — defer until needed.

## 2026-05-03 — Two-pass apply fix: PATH prep + Python

**Why:** The revision 3 install script silently failed to update user PATH and
create `~/bin` (likely ran in a subprocess where `SetEnvironmentVariable` to
'User' succeeded in the registry but returned before verification). As a
result, `chezmoi apply` still resolved `bash` to
`C:\Users\Rai\AppData\Local\Microsoft\WindowsApps\bash.exe` (WSL stub, which
is an app execution alias and cannot be spawned as a child process), causing
the modify_ scripts to fail with `%1 is not a valid Win32 application`.

**What changed:**

- Did the PATH prep directly from the active PS session:
  - Prepended `C:\Program Files\Git\bin` to persistent user PATH (registry).
  - Created `C:\Users\Rai\bin` directory.
  - Wrote `C:\Users\Rai\bin\python3.cmd` shim (`@py -3 %*`).
- Installed Python.Python.3.13 via winget (py launcher at
  `C:\Users\Rai\AppData\Local\Programs\Python\Launcher\py.exe`).
- `pip --user install tomli tomli_w` — verified both importable.
- Bumped install script to revision 4 so it re-runs idempotently on the
  next apply and confirms the final state.

**Next step:** Open a new PowerShell window (to pick up the updated PATH)
and run `chezmoi apply`. With Git bash now first on PATH, the four
modify_ scripts should run successfully. 1Password desktop integration must
be active for the profile template to render secrets.

## 2026-05-03 — Replace modify_dot_claude.json.tmpl with PS run_onchange on Windows

**Why:** chezmoi maps `modify_dot_claude.json.tmpl` to target `.claude` (stripping
the `dot_` → `.` and losing `.json`), which collides with the `dot_claude/` source
directory (also targeting `.claude`). chezmoi throws `inconsistent state` and aborts.
This is a Windows-specific bug — Linux/macOS resolves them as distinct targets.

**What changed:**

- `.chezmoiignore` Windows block: added `.claude.json` so the bash modify script is
  skipped on Windows.
- New `run_onchange_apply-claude-json-windows.ps1`: PowerShell equivalent of
  `modify_dot_claude.json.tmpl`. Uses jq (installed via winget) with `--slurpfile` to
  merge the authoritative MCP server list into `~/.claude.json` and scrub the
  poisoned 1M-context cache keys. Re-runs when this file changes (same trigger as
  bumping the bash modify script).
- `.chezmoiignore` non-Windows block: added `run_onchange_apply-claude-json-windows.ps1`
  so it's ignored on Linux/macOS.
- `[interpreters.json]` and `[interpreters.toml]` added to local `chezmoi.toml` earlier
  in this session — these are still needed for `modify_settings.json`,
  `modify_settings.local.json`, and `modify_private_config.toml` (those scripts are
  inside `dot_claude/` and `dot_codex/` directories and don't have the naming conflict,
  but they still need interpreter routing on Windows).

## 2026-05-03 — Fix nvim config not loading (XDG_CONFIG_HOME mismatch)

**Why:** After cloning the AstroNvim config to `%LOCALAPPDATA%\nvim`, nvim
opened with default config and `Lazy! sync` failed with `E492: Not an editor
command`. The custom config wasn't loading at all.

**Root cause:** The PowerShell profile sets `$env:XDG_CONFIG_HOME = "$HOME\.config"`.
When Neovim sees this env var, `stdpath('config')` resolves to
`C:\Users\Rai\.config\nvim` instead of the default `C:\Users\Rai\AppData\Local\nvim`.
The install script cloned to `%LOCALAPPDATA%\nvim` but nvim was looking in
`~\.config\nvim\` — path mismatch, so nvim found no init.lua, never bootstrapped
Lazy.nvim, and the `Lazy!` command didn't exist.

**What changed:**

- `run_onchange_install-nvim-windows.ps1.tmpl` (revision 2): now mirrors the
  XDG_CONFIG_HOME logic from the PS profile. Sets `$env:XDG_CONFIG_HOME` to
  `$HOME\.config` if not already set, then targets `$XDG_CONFIG_HOME\nvim` as the
  clone destination. Includes a migration path: if the config already exists at
  `%LOCALAPPDATA%\nvim` (legacy location), it is moved rather than re-cloned.
  Parent directory (`~\.config`) is created if absent.
- Moved the existing clone from `C:\Users\Rai\AppData\Local\nvim` to
  `C:\Users\Rai\.config\nvim` on the live system.
- Verified: `nvim --headless "+Lazy! sync" "+qa"` now succeeds — Lazy.nvim
  bootstraps and syncs all plugins.

**Why this works with and without XDG_CONFIG_HOME:** The script always sets
`XDG_CONFIG_HOME` to `$HOME\.config` if unset (matching the PS profile default),
so the clone destination is deterministic. If the profile changes its XDG_CONFIG_HOME
value in the future, the script follows suit.

## 2026-05-15 — Fix Windows scripts running on macOS/Linux

**Why:** `chezmoi apply` on macOS hit `exec format error` on
`apply-claude-json-windows.ps1` — the PowerShell script was being
executed despite the non-Windows ignore block in `.chezmoiignore`.

**Root cause:** `.chezmoiignore` patterns match against **target** paths.
For `run_onchange_*` scripts, chezmoi strips the `run_onchange_` prefix
to derive the target name. The ignore block listed the source name
(`run_onchange_apply-claude-json-windows.ps1`) but not the target name
(`apply-claude-json-windows.ps1`). The other three Windows scripts
worked because they had both forms listed.

**What changed:**

- `.chezmoiignore` non-Windows block: added `apply-claude-json-windows.ps1`
  (target name) so it's properly ignored alongside the source-name pattern.
- Also added `.config/mpv/scripts/uosc/bin/ziggy-windows.exe` — the
  Windows binary for mpv's uosc plugin was being deployed unnecessarily
  on macOS/Linux.
