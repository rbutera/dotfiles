# pi / oh-my-pi (omp) changes log

## 2026-07-13 — Install pi + oh-my-pi on nimbus to match kinto

### Problem
nimbus had neither `pi` nor `omp` installed; goal was to match the working
install on `kinto` (reachable over tailscale). Inspected kinto's install to
replicate exact versions.

### kinto install (the target)
- **`pi`** = npm global `@earendil-works/pi-coding-agent@0.80.3`, run under asdf
  nodejs 24.16.0, exposed via the asdf shim `~/.asdf/shims/pi`.
- **`omp`** (oh-my-pi) = bun global `@oh-my-pi/pi-coding-agent@16.4.8`
  (`omp/16.4.8`) at `~/.bun/bin/omp`. bun 1.3.14.

### Changes on nimbus
- `npm install -g @earendil-works/pi-coding-agent@0.80.3` then `asdf reshim
  nodejs` → `pi` shim created.
- `bun install -g @oh-my-pi/pi-coding-agent@16.4.8` → `~/.bun/bin/omp`.
- node 24.16.0 and bun 1.3.14 already matched kinto; no toolchain change needed.
- `~/.pi/agent/auth.json` deployed via chezmoi (`dot_pi/agent/modify_private_auth.json`
  merge-script) during the same session's chezmoi-sync.

### Verification
`pi --version` → `0.80.3`; `~/.bun/bin/omp --version` → `omp/16.4.8` — both match
kinto. `omp` resolves on the login PATH (`~/.bun/bin` is exported from the merged
`dot_zshenv.tmpl`).

### Note
The install matches kinto's binaries/versions; `pi` may still need an interactive
`pi` login to populate real auth tokens in `~/.pi/agent/auth.json` (the chezmoi
merge-script only seeds the managed base). Not done in this session.
