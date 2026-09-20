# gog (Google CLI) log

## 2026-09-20 — Replicate gog auth for rai@rbutera.com onto latios

### Problem / motivation
Agentic work on latios (Tilly, `~/tilly`) needs Gmail access. gog was authed only on nimbus (this Mac). Wanted the same credential store on both machines rather than a fresh OAuth dance per host.

### How gog is set up (both machines now)
- Config root: `~/Library/Application Support/gogcli/` (macOS). `config.json` sets `keyring_backend: file`; `credentials.json` is the OAuth client; `keyring/` holds refresh tokens encrypted with `GOG_KEYRING_PASSWORD`.
- `GOG_KEYRING_PASSWORD` is exported by `dot_config/zsh/tools.zsh.tmpl` from `op://Private/GOG Keyring Password/credential`, so it is already identical on every chezmoi-managed host. That is what makes the keyring portable: copy the files, same password decrypts them.
- gog exits 0 and silently no-ops when that variable is missing (non-interactive shells, cron). Prefix with `source ~/.config/zsh/tools.zsh` and check `gog auth doctor` reports `status ok`.

### What was changed
- latios: `brew install gogcli` (0.40.0; nimbus is on 0.31.1, keyring format compatible).
- Copied from nimbus to latios: `credentials.json`, a `config.json` with only `keyring_backend: file` (dropped the `emma` account-client mapping; Emma's tokens deliberately not copied), and the five rai keyring entries (`token:default:rai@rbutera.com`, `token:rai@rbutera.com`, `token-sub:default:…`, plus the two legacy plain-named files). Modes 600.
- Verified on latios: `gog auth doctor` ok, `gog auth list` shows rai@rbutera.com with full scopes, `gog gmail labels list` and a `messages search` returned real data.
- Installed `~/tilly/.claude/skills/gog-gmail/SKILL.md` on latios: navi's `gog-gmail` skill with Navi→Tilly wording and a "Setup on latios" section pointing at the config location and the env-var pitfall.

### Not done
- gog config/keyring is not chezmoi-managed (encrypted refresh tokens plus an OAuth client secret in git is not worth it). New host recipe: install gog, copy the three files above, done.
- Refresh token is shared across hosts; revoking it (Google account security page) kills both machines at once.

## 2026-09-20 — Cross-harness `gog` skill

### Problem / motivation
Only Navi had gog instructions (`~/navi/skills/gog-gmail`, Gmail only). Every harness on every machine should know how to reach Rai's mail, calendar and Drive.

### What was changed
- New skill `dot_agents/skills/gog/SKILL.md` (`~/.agents/skills/gog`): keyring unlock preamble, `--json`/`--readonly` conventions, the `threads`-not-`messages` and spam/trash search pitfalls, command cheatsheet for Gmail, Calendar, Drive/Docs/Sheets, Contacts/Tasks, approval gate for anything that sends or shares, setup/repair pointer. Flag names checked against `gog --help` (0.31.1).
- `dot_claude/skills/symlink_gog.tmpl` and `dot_codex/skills/symlink_gog.tmpl` point `~/.claude/skills/gog` and `~/.codex/skills/gog` at the `.agents` copy, so one file serves all three harnesses. First use of chezmoi `symlink_` in this repo.
- Applied on nimbus and latios (`chezmoi apply` on the three targets only; no 1Password needed). Latios pull surfaced 7 unpushed impulse commits and a one-hunk conflict in `dot_config/impulse/jobs.json.tmpl` (Tilly jobs vs the nimbus disable-comment); merged keeping both, rendered JSON validated, pushed.
