# SSH Config Changelog

## 2026-04-17 -- Added expedition VPS

### Problem
New Hetzner CAX21 VPS (expedition) created for self-hosted Plane + Dumbledore. Need SSH access from nimbus.

### Solution/Fix
Added `Host expedition` entry to `dot_ssh/config.tmpl` pointing at `178.104.126.229`, user `rai`, using `id_ed25519` key with ForwardAgent.
