# SSH Config Changelog

## 2026-07-14 — Re-removed the colima Include (self-inflicted regression) + guard comment

### What happened

During a `/chezmoi-sync` walk, `~/.ssh/config` showed two colima `Include` lines
present in the deployed file but absent from the template. I misread this as
"template is missing config" and added them back, `stat`-guarded, reasoning that
colima re-injects them anyway so the template should own them.

**That was wrong** — it re-introduced the exact bug fixed by `f87711c`
(2026-06-27, "remove colima Include to prevent config abort on inaccessible
external volume"). OpenSSH is **fatal** on an *unreadable* include (silent only
on a *missing* one), so when `/Volumes/ExternalNVMe` is unmounted the include
aborts parsing of the entire ssh config. The `stat` guard does not help: `stat`
is evaluated at **apply** time, while the failure occurs later, whenever the
volume goes away.

The bad edit was picked up and committed by an unrelated autonomous
drift-committer (`cebe62a`) before it could be caught.

### What changed

- **`dot_ssh/config.tmpl`**: colima Include block removed again. In its place, a
  comment recording *why* it must not come back, so the next sync (human or
  agent) doesn't re-derive the same wrong conclusion from the same drift.
- Re-applied `~/.ssh/config`; verified `ssh -G pidgey` parses cleanly.

### The rule

The deployed-vs-source drift on `~/.ssh/config` (colima's injected Includes) is
**expected and benign**. Colima re-adds them on VM start. Keep SOURCE; never
back-port them into the template.

## 2026-07-13 -- Preserve nimbus-only `expedition-vps-backup` authorized key (chezmoi-sync)

### Problem
The deployed `~/.ssh/authorized_keys` on nimbus had a second public key,
`expedition-vps-backup` (the Expedition VPS's key for pulling backups off nimbus),
that `dot_ssh/authorized_keys.tmpl` didn't render — so `chezmoi apply` would have
**revoked** it. The template previously rendered only the primary
`op://Private/ed25519_rbutera/public key`.

### Key detail — machine-specific
kinto's `authorized_keys` does **not** carry this key (verified over tailscale);
it's specific to nimbus (the Expedition infra host). Adding it unconditionally to
the shared template would wrongly authorize it on every machine.

### Changes
- `dot_ssh/authorized_keys.tmpl`: appended the `expedition-vps-backup` public key
  behind a `{{ if eq .chezmoi.hostname "nimbus" }}` guard, matching the repo's
  hostname-gating pattern. Public key stored literally (public keys aren't secret).

### Verification
`chezmoi execute-template` on nimbus renders byte-identical to the deployed
`~/.ssh/authorized_keys` (both keys); other hosts render only the primary key.

## 2026-04-17 -- Added expedition VPS

### Problem
New Hetzner CAX21 VPS (expedition) created for self-hosted Plane + Dumbledore. Need SSH access from nimbus.

### Solution/Fix
Added `Host expedition` entry to `dot_ssh/config.tmpl` pointing at `178.104.126.229`, user `rai`, using `id_ed25519` key with ForwardAgent.

## 2026-06-27 -- Remove colima Include to prevent ssh config abort on unreadable external volume

### Problem
`~/.ssh/config` had two `Include` lines near the top pointing at colima's ssh_config:
- `Include /Volumes/ExternalNVMe/home/.colima/ssh_config` (auto-injected by colima on start)
- `Include /Users/rai/.colima/ssh_config` (added by chezmoi template via `stat` guard)

`~/.colima` is a symlink to `/Volumes/ExternalNVMe/home/.colima`. When the external NVMe is inaccessible (TCC/permission denied on the volume), OpenSSH treats the permission-denied Include as fatal and aborts the ENTIRE config parse. This broke ALL ssh including `git push`, dolt sync, and every host in the config. Worked around in the short term with `ssh -F /dev/null -i ~/.ssh/id_ed25519 ...`.

Root cause: the chezmoi template's `stat` guard only prevents the Include at template-render time. If chezmoi was applied while the drive was accessible, the Include persists in the rendered `~/.ssh/config`. OpenSSH ignores a MISSING include file (silently, since 7.3+) but kills the parse on permission denied -- so "file exists but unreadable" is fatal whereas "file absent" is safe.

### Solution/Fix
Removed the colima block from `dot_ssh/config.tmpl` entirely:
```
{{- if stat "/Users/rai/.colima/ssh_config" }}
Include /Users/rai/.colima/ssh_config
{{- end }}
```

Rationale: colima auto-injects its own Include into `~/.ssh/config` when started (`colima start`), so the template block was redundant. When colima is down/inaccessible, the colima ssh_config is useless anyway (the VMs aren't running). Removing it from the template means `chezmoi apply` produces a config with no colima Include -- ssh cannot be broken by an inaccessible external volume.

The orbstack block (`~/.orbstack/ssh/config`) is unchanged; it uses a local path that is always readable when OrbStack is installed.

Applied via `chezmoi apply --force ~/.ssh/config`. Verified: `ssh -G github.com` and `ssh -G nimbus` both parse cleanly with no errors.

## 2026-04-29 -- Fix lancelot SSH hostname

### Problem
`ssh rai@lancelot` timed out because the Tailscale IP in SSH config (`100.73.34.7`) was stale. Actual current IP is `100.87.255.86` (confirmed via `tailscale status`).

### Solution/Fix
Updated `dot_ssh/config.tmpl` to use current Tailscale IP `100.87.255.86`. Applied via `chezmoi apply ~/.ssh/config`. Note: Tailscale IPs can change; if this happens again, check `tailscale status` for the current IP.
