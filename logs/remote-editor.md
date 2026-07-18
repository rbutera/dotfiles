# Remote Editor (code / cursor over SSH) Changelog

Shell functions in `dot_aliases.tmpl` (macOS/darwin block) that make `code`
and `cursor` open on the *connecting client* when you're SSH'd into this Mac,
via Remote-SSH back into this host — instead of opening locally.

## 2026-07-03 — Fix broken `code`, add `cursor`, use Tailscale IP not hostname

### Problem
The existing `code()` function (reverse-SSH: SSH back to the connecting client
and run `code --remote ssh-remote+<host> <path>`) silently did nothing when
SSH'd in from Lancelot (WSL). There was no `cursor` equivalent at all.

Root causes found by testing from a live tmux SSH session (Lancelot → kinto):
1. **Editor not on PATH on the client.** In a non-interactive SSH shell on
   Lancelot, neither `code` nor `cursor` is on `PATH` — not even via
   `zsh -lc` / `bash -lc`. So the reverse command was "command not found".
2. **Error swallowed.** `systemd-run --user --no-block` discarded the failure,
   so nothing surfaced.
3. **Wrong launch branch for WSL.** The function chose the `systemd-run` branch
   whenever `systemd-run` existed — but WSL *has* `systemd-run`, so it took the
   Wayland-Linux path (meant for the Arch boxes) instead of launching the
   Windows shim.
4. **Hostname target depends on MagicDNS.** `ssh-remote+<hostname>` requires the
   client to resolve `<hostname>` (MagicDNS or an ssh config Host entry), which
   isn't always available.

Verified on the client (Lancelot): the real editor shims exist at fixed paths —
`/mnt/c/Users/Rai/AppData/Local/Programs/cursor/resources/app/bin/cursor` and
`.../Microsoft VS Code/bin/code`.

### Solution/Fix
Replaced the single `code()` with a shared `_remote_editor()` helper plus thin
`code()` / `cursor()` wrappers (all in the `{{ if eq .chezmoi.os "darwin" }}`
block of `dot_aliases.tmpl`).

`_remote_editor <editor> [path]` reverse-SSHes to the connecting client and:

- **Resolves the client binary** in order: `command -v <editor>` (native
  Linux/macOS clients) → glob `/mnt/c/Users/*/AppData/Local/Programs/<winprog>/resources/app/bin/<editor>`
  (WSL clients). Errors to stderr with exit 127 if not found (no longer silent).
- **Dispatches the launch by client type:** WSL (`/proc/version` contains
  `microsoft`) → run the Windows shim, backgrounded with `nohup`; Wayland Linux
  → `systemd-run --user` to inherit the compositor env; else (macOS/X11) → run
  directly, backgrounded.
- **Targets this host by Tailscale IP, not hostname.** The Remote-SSH authority
  is `<user>@<server_ip>`, where `server_ip` is the 3rd field of
  `$SSH_CONNECTION` (the exact address the client used to reach us) — so it does
  not depend on MagicDNS. Override with `$REMOTE_EDITOR_HOST` (e.g. a name in the
  client's `~/.ssh/config`) if preferred.
- **Passes values safely** across the SSH boundary via env-var assignments
  quoted with zsh `${(q)...}`, so paths with spaces and the `Microsoft VS Code`
  program dir survive.

Local invocation (no `$SSH_CONNECTION`) and integrated-terminal invocation
(`$VSCODE_IPC_HOOK_CLI` set) both fall through to `command <editor> "$@"`.

### Verification
- Reverse round-trip `kinto → Lancelot → ssh rai@100.65.116.84` (raw Tailscale
  IP) authenticates with no host-key/user prompt — confirms `ssh-remote+<ip>`
  will work on the client without MagicDNS.
- `zsh -n ~/.aliases` passes; `chezmoi apply ~/.aliases` needs no 1Password.
- Live `cursor ~/.local/share/chezmoi` through the deployed function returns
  exit 0 and launches the Cursor Remote-SSH window on the client.
