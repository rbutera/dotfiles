## 2026-07-19

**Problem/motivation:** Chaching's nightly history refresh existed only as a hand-installed, Kinto-specific launch agent, so Latios and Nimbus could not publish their local usage into the shared PostgreSQL pool.

**Changes:** Added a `chaching` host group for Kinto, Latios, and Nimbus, exported `CHACHING_DATABASE_URL` on those hosts from `op://dev/Neon Chaching Connection String/credential`, and added a portable macOS launch agent that resolves the globally installed Chaching CLI from each machine's managed toolchain paths and runs `chaching stats --no-art` nightly at 23:50.

## 2026-11-08 -- chaching serve on nimbus, published as chaching.e8n.dev

### Problem
Rai wanted the pooled chaching dashboard reachable off the tailnet.

### Solution/Fix
Added `Library/LaunchAgents/com.chaching.serve.plist.tmpl` (nimbus only, via `.chezmoiignore`): `chaching serve` with HOST=127.0.0.1, PORT=4891 (serve --port is ignored), ORIGIN=https://chaching.e8n.dev, KeepAlive. Needs chaching >= 1.19.1 (scans at boot). Published through the e8n Cloudflare tunnel and Caddy, gated by a Cloudflare Access app (rai@rbutera.com only). Runbook: ~/expedition/Nimbus Operations.md.
