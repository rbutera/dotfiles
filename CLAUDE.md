# CLAUDE.md — Dotfiles Agent Guide

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Owner: Rai Butera (`rai@rbutera.com`).

## Agent requirements

- **Always update the relevant log file** in `logs/` after making changes. Each file is a dated changelog for a topic (e.g. `logs/tmux.md`). If no log exists for the topic yet, create one. Entries must include today's date, a summary of the problem/motivation, and what was changed. Use the existing entries in `logs/tmux.md` as a style reference.

## Golden Rule: never leave the source repo dirty

**If you find this chezmoi source repo (`~/.local/share/chezmoi`) dirty, commit and push it. Every time.** Never leave it dirty, never `git stash`-and-forget.

Process:
1. `git -C ~/.local/share/chezmoi status` — see what changed.
2. **Inspect every diff, including ones you didn't author.** Drift accumulates from real config Rai evolved on a machine (brewfiles, karabiner/kanata, plists, host config).
3. If the diffs look sane / match the deployed files (i.e. they're genuine config, not junk or a half-broken edit), stage the specific paths, commit with a clear message describing what drifted, and `git push`.
4. If a diff looks wrong or suspicious, surface it to Rai rather than committing it — but still don't leave it sitting dirty.

Rationale (Rai, 2026-07-01): dirty source = single-source-of-truth drift between what's deployed and what's tracked. Leaving it dirty is how the deployed machine and the repo silently diverge. Pushing autonomously is expected — same posture as always-push-chezmoi-autonomously. Ties to the impulse-reload rule and the wider "kill drift in my own stack" doctrine.

## Critical Constraint: chezmoi apply requires 1Password

**Agents cannot run `chezmoi apply` without prior user action.**

All secret values in templates are fetched via `onepasswordRead` (chezmoi's 1Password template function), which calls `op read` under the hood. This triggers an interactive 1Password authentication prompt that agents cannot fill in.

### Workaround (session token)

If the user has recently authenticated in their shell, `OP_SESSION_personal` is already set in the environment. Agents inherit this and `chezmoi apply` will succeed without prompting. This token expires after 30 minutes of inactivity.

To check if a valid session exists before attempting apply:
```bash
timeout 12 op vault list >/dev/null 2>&1; echo $?   # 0 = authenticated, 124 = prompting (no session)
```

⚠️ **The check documented here until 2026-08-02 was `op account list 2>/dev/null | grep -q personal`, and it could NEVER return true.** Measured on this machine: `op account list` prints only URL, email and user id, and `op account list --format=json` shows the account has **no `shorthand` field at all** (`url: my.1password.com`). There is no string `personal` anywhere in that output, so the grep always failed and the check could only ever report "no session" regardless of the truth. The local chezmoi config agrees: `~/.config/chezmoi/chezmoi.toml` identifies the account as `account = "my.1password.com"`, not by an alias.

The replacement uses an authenticated call that touches no secret. **Read the exit code, not the output.** `124` means `op` sat waiting for an interactive unlock, which is the real "no session" signal on this machine.

⚠️ **A caveat on that check, stated because it bit the run that wrote this**: a deliberately-invalid control (`op vault get <nonexistent>`) ALSO returns 124, because it prompts before it validates. So 124 means "would prompt", not specifically "auth failed". `0` is the only unambiguous reading, and it is the one that matters here.

`OP_SESSION_personal` is named above by the same broken assumption. Measured: no `OP_SESSION_*` variable is set in an agent shell at all; the only `OP_*` variable present is `OP_ACCOUNT`.

If no session is active, tell the user to run `eval $(op signin)` first, then re-run the agent task.

### Config to prevent hanging on expired sessions

Add to `~/.config/chezmoi/chezmoi.toml` (the local config, not the source template):
```toml
[onepassword]
  prompt = false
```
This makes chezmoi fail fast with an error rather than hanging on a prompt when the session has expired.

### Long-term solution (not yet implemented)

The proper non-interactive solution is a 1Password Service Account + new vault, but this requires migrating all `op://Private/...` secrets to a new custom vault (service accounts cannot access the built-in `Private` vault). See future work section below.

---

## Safe Agent Workflow

```bash
chezmoi diff                        # Preview what would change — always safe, no 1Password needed
chezmoi execute-template < file.tmpl  # Render a template for inspection (requires 1Password session)
chezmoi apply                       # Apply ALL changes (requires active 1Password session)
chezmoi apply --dry-run             # Dry run (still requires 1Password to render templates)

# Apply a specific target file — only triggers 1Password if THAT file uses onepasswordRead
chezmoi apply ~/.config/hypr/custom/keybinds.conf
chezmoi apply ~/.config/hypr/custom/general.conf
```

**Applying individual files without 1Password:** `chezmoi apply <target-path>` processes only that file. If the source file contains no `onepasswordRead` calls, 1Password is never invoked. This is safe to do at any time for plain config files (e.g. anything under `dot_config/hypr/` or the Windows main PowerShell profile at `Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`).

**To check whether a source file uses 1Password before applying:**
```bash
grep -l onepasswordRead $(chezmoi source-path ~/.config/hypr/custom/keybinds.conf)
# No output = safe to apply without a session
```

**Editing source files** (anything in `~/.local/share/chezmoi/`) is always safe. No auth required. Always edit source files, never the deployed targets directly.

---

## Repository Structure

```
chezmoi source dir: ~/.local/share/chezmoi/
├── dot_zshrc.tmpl          → ~/.zshrc
├── dot_zshenv.tmpl         → ~/.zshenv   ← where env vars / secrets are exported
├── dot_zprofile.tmpl       → ~/.zprofile
├── dot_aliases.tmpl        → ~/.aliases
├── dot_gitconfig.tmpl      → ~/.gitconfig
├── dot_env.tmpl            → ~/.env
├── .chezmoi.toml.tmpl      → chezmoi config template (prompts for email, name on first run)
├── .chezmoiexternal.toml   → external git deps (zsh-z)
├── .chezmoiignore          → conditional ignores by OS/WSL
├── dot_config/             → XDG config (~/.config/*)
│   ├── kitty/              → terminal (Catppuccin themes)
│   ├── aichat/             → AI chat (GPT-4o)
│   ├── starship.toml       → prompt
│   └── ...
├── dot_ssh/                → SSH config
├── dot_tmux/               → tmux + TPM
├── dot_claude/             → Claude Code settings
├── navi/ark.json.tmpl      → ~/navi/ark.json (Ark workspace config)
├── focused/ark.json.tmpl   → ~/focused/ark.json (Ark workspace config)
├── bin/                    → custom executables (deployed to ~/bin/)
├── run_once_*.sh.tmpl      → bootstrap scripts (see warning below)
└── docs/                   → documentation
```

---

## Platforms

Targets: **macOS**, **Arch Linux** (primary: CachyOS), **Ubuntu/Debian**, **WSL Ubuntu**.

Templates use these detection variables:

| Variable | Values | Usage |
|---|---|---|
| `.chezmoi.os` | `darwin`, `linux` | Top-level OS branch |
| `.chezmoi.osRelease.id` | `arch`, `ubuntu`, `debian`, `fedora` | Distro-specific |
| `.chezmoi.osRelease.idLike` | `arch` (for AUR-compatible) | Distro family |
| `.chezmoi.kernel.osrelease` | contains `WSL2` | WSL detection |
| `.wsl` | `true`/`false` | Computed in `.chezmoi.toml.tmpl` |
| `.chezmoi.hostname` | e.g. `mondo` | Hostname-specific config |
| `.name` | `Rai Butera` | Git config |
| `.email` | `rai@rbutera.com` | Git config |

### Hostname Groups

Machine-specific feature flags are defined in `.chezmoidata.toml`. Example:

```toml
# .chezmoidata.toml — hostname group definitions
[host_groups]
  niri = ["mondo"]
  kde  = []
```

Then in templates:
```
{{- if has .chezmoi.hostname .host_groups.niri }}
# niri-specific config
{{- end }}
```

To add a machine to a group, just append its hostname to the array — all templates pick it up automatically.

### Distro detection pattern

```
{{- if or (eq .chezmoi.osRelease.id "arch") (and (hasKey .chezmoi.osRelease "idLike") (eq .chezmoi.osRelease.idLike "arch")) }}
# Arch / AUR-compatible
{{- end }}
```

Always use `hasKey .chezmoi.osRelease "idLike"` before accessing `idLike` — it may be absent on minimal installs.

---

## 1Password Integration

Secrets are read at template render time via:
```
{{ onepasswordRead "op://VaultName/ItemName/field" }}
```

**Vaults in use:**
- `op://Private/` — primary vault (API keys, credentials, passwords)
- `op://dev/` — dev vault (GitHub tokens, GPG keys)

**Where secrets live in source:**
- `dot_zshenv.tmpl` — all exported environment variables / API keys (edit this directly)
- `dot_gitconfig.tmpl` — git user identity
- `dot_aider.conf.yml.tmpl` — Aider AI config
- `dot_ssh/` — SSH keys via `op://Private/ed25519_rbutera/openssh`
- `run_once_11_setup_gpg.sh.tmpl` — GPG import from `op://dev/GPG_rai_at_rbutera.com/*`
- `Documents/PowerShell/Microsoft.PowerShell_profile.secrets.ps1.tmpl` — Windows PowerShell secret environment variables. The main Windows profile template dot-sources the rendered sibling file and is safe to edit/apply without a 1Password session.

### Adding a new secret/API key

Edit `dot_zshenv.tmpl` directly. Add a new line following the existing pattern:
```
export MY_NEW_KEY={{ onepasswordRead "op://Private/item-name/credential" }}
```

Do **not** use `bin/executable_add-api-key` — it's broken (runs `chezmoi apply` internally).

### SSH over 1Password

The zshrc sets these when connecting over SSH:
```bash
export OP_BIOMETRIC_UNLOCK_ENABLED=false
export OP_ACCOUNT=personal
```

This tells the `op` CLI to use the `personal` account alias and skip biometric unlock.

---

## Run-Once Bootstrap Scripts

`run_once_*.sh.tmpl` scripts install toolchains and packages on new machines. **They are currently broken and unreliable** — do not attempt to fix or run them without explicit user instruction. They require manual intervention on new machine setup.

Scripts (in order):
1. `run_once_01_install-zsh.sh.tmpl` — install zsh
2. `run_once_02_install_prezto_and_contrib.sh.tmpl` — Prezto framework
3. `run_once_03_install-packages.sh.tmpl` — Homebrew/apt/pacman packages
4. `run_once_03b_install-aur-packages.sh.tmpl` — AUR packages (Arch only)
5. `run_once_05_install-editor.sh.tmpl` — Neovim via bob
6. `run_once_06_install-tpm.sh.tmpl` — Tmux Plugin Manager
7. `run_once_07_install-go.sh.tmpl` — Go installation
8. `run_once_08_setup_1password_alias.sh.tmpl` — 1Password macOS symlink
9. `run_once_09_setup_rust.sh.tmpl` — Rust toolchain
10. `run_once_10_setup_node.sh.tmpl` — Node.js via asdf
11. `run_once_11_setup_gpg.sh.tmpl` — GPG import from 1Password

---

## Key Tools Managed

| Tool | Config location | Notes |
|---|---|---|
| zsh + Prezto | `dot_zshrc.tmpl`, `dot_zpreztorc.tmpl` | vi-mode, starship prompt |
| Neovim | `dot_config/nvim/` | via bob version manager |
| tmux | `dot_tmux/` | Catppuccin theme, TPM |
| Kitty | `dot_config/kitty/` | Primary terminal |
| Ghostty | `dot_config/ghostty/` | Secondary terminal |
| Git | `dot_gitconfig.tmpl` | delta diff viewer |
| aichat | `dot_config/aichat/` | GPT-4o, function calling |
| aider | `dot_aider.conf.yml.tmpl` | Claude 3.5 Sonnet |
| Claude Code | `dot_claude/` | Anthropic CLI |
| 1Password | systemd service + `run_once_08` | GUI + CLI |
| Kanata | `dot_config/kanata/` | keyboard remapper (Linux) |
| Karabiner | `dot_config/karabiner/` | keyboard remapper (macOS) |

---

## Common Operations

```bash
# Preview changes before applying
chezmoi diff

# Edit a source file (preferred over editing the deployed target)
chezmoi edit ~/.zshrc          # opens source in $EDITOR, applies on save
# or edit directly:
nvim ~/.local/share/chezmoi/dot_zshrc.tmpl

# After editing source files, apply (requires 1Password session):
chezmoi apply

# Re-render and inspect a specific template
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshenv.tmpl

# Pull latest and apply
chezmoi update

# Check chezmoi status
chezmoi status
```

---

## Future Work

- **1Password service account**: Migrate all `op://Private/...` items to a new custom vault (e.g. `dotfiles-automation`), create a service account with read access, store `OP_SERVICE_ACCOUNT_TOKEN` in a systemd credential or similar, add `[onepassword] mode = "service"` to chezmoi config. This enables fully non-interactive `chezmoi apply` for agents.
- **Niri on `mondo`**: `.chezmoidata.toml` `host_groups.niri` is set up — templates still need conditional blocks added where relevant.
- **Fix run_once scripts**: Audit and repair bootstrap scripts for reliable new-machine setup.
