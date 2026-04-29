# SSH Config Changelog

## 2026-04-17 -- Added expedition VPS

### Problem
New Hetzner CAX21 VPS (expedition) created for self-hosted Plane + Dumbledore. Need SSH access from nimbus.

### Solution/Fix
Added `Host expedition` entry to `dot_ssh/config.tmpl` pointing at `178.104.126.229`, user `rai`, using `id_ed25519` key with ForwardAgent.

## 2026-04-29 -- Fix lancelot SSH hostname

### Problem
`ssh rai@lancelot` timed out because the Tailscale IP in SSH config (`100.73.34.7`) was stale. Actual current IP is `100.87.255.86` (confirmed via `tailscale status`).

### Solution/Fix
Updated `dot_ssh/config.tmpl` to use current Tailscale IP `100.87.255.86`. Applied via `chezmoi apply ~/.ssh/config`. Note: Tailscale IPs can change; if this happens again, check `tailscale status` for the current IP.
