# Docker infrastructure changelog

## 2026-04-15 — Install Colima + Docker CLI on latios

### Motivation
`DOCKER_HOST` was already exported unconditionally for macOS in
`dot_zshenv.tmpl:45` (pointing at `~/.colima/default/docker.sock`), but the
actual engine and CLI had never been installed on this machine. Needed a
working `docker` / `docker compose` on latios so the existing
`~/docker/compose.yml` stack (and ad-hoc container work) can run.

Scoped to latios only — the user explicitly asked for "only on this
machine", so the Brewfile gates the install on the `work` host group
rather than all darwin hosts.

### Pre-req: hostname fix
`.chezmoi.hostname` was resolving to `ip-10-253-101-202` (AWS DHCP
hostname bleeding into `uname -n` / `kern.hostname`) instead of `latios`,
so the `work = ["latios"]` host group never matched. macOS has three
independent hostname fields — `LocalHostName` and `ComputerName` were
both `Latios` via `scutil`, but the kernel `HostName` was unset, so the
system fell back to the DHCP-supplied fqdn.

Fix:
```sh
sudo scutil --set HostName latios
```
This is persistent and overrides DHCP. After the fix, `chezmoi data`
reports `hostname = "latios"` and `host_groups.work` matches correctly.
Any other macOS host behind AWS DHCP that wants to match a host group
will need the same one-shot fix.

### Changes

**Modified files:**
- `raisbrewfile.tmpl` — added a darwin-only, `work`-gated block with
  `colima`, `docker`, `docker-compose`, `docker-buildx`. Nested inside
  the existing darwin conditional so non-work Macs (none today, but
  future-proof) don't pull a ~300 MB Docker VM toolchain they won't use.

**Manual steps run on latios (not templated):**
- `brew install colima docker docker-compose docker-buildx`
- Created `~/.docker/config.json` with
  `cliPluginsExtraDirs: ["/opt/homebrew/lib/docker/cli-plugins"]` so the
  Homebrew-installed compose/buildx plugins are discoverable by the
  `docker` CLI. Colima's `docker context use colima` step later added
  `currentContext` and `auths` to the same file — both entries coexist.
- `colima start --cpu 4 --memory 8 --disk 60` — first-time VM create
  with sensible M-series defaults. Verified with `docker run --rm
  hello-world` against the `linux/arm64` image.

### Notes
- Colima is **not** registered with `brew services` — it must be started
  manually with `colima start` after reboot. If always-on is preferred,
  run `brew services start colima`. Left off by default because the VM
  reserves 4 CPU / 8 GiB / 60 GiB and shouldn't run when unused.
- `DOCKER_HOST` in `dot_zshenv.tmpl:45` points at
  `~/.colima/default/docker.sock` unconditionally for darwin. The
  env var shadows `docker context`, which is why `docker version` shows
  `Context: default` even though colima sets its own context. Harmless —
  the env var points at the same socket — but it's the reason for the
  `DOCKER_HOST environment variable overrides the active context`
  warning at `colima start` time.
- `~/.docker/config.json` is *not* managed by chezmoi. It's written by
  the docker CLI itself (credentials, context) so it needs to stay
  mutable. If the `cliPluginsExtraDirs` entry ever gets clobbered,
  re-add it manually.

### Reapply checklist for a new work Mac
1. `sudo scutil --set HostName <latios-equivalent>` if `chezmoi data`
   reports an AWS/DHCP hostname.
2. Ensure the hostname is in `host_groups.work` in `.chezmoidata.toml`.
3. `chezmoi apply` (installs via Brewfile on next `run_once_03` run, or
   `brew bundle --file=<(chezmoi execute-template < ~/.local/share/chezmoi/raisbrewfile.tmpl)`).
4. `mkdir -p ~/.docker && echo '{"cliPluginsExtraDirs":["/opt/homebrew/lib/docker/cli-plugins"]}' > ~/.docker/config.json`
   (only if the file doesn't exist yet; otherwise merge the key in).
5. `colima start --cpu 4 --memory 8 --disk 60`.
6. `docker run --rm hello-world` to smoke-test.

## 2026-04-08 — Initial local infra setup

### Motivation
Set up a chezmoi-managed Docker Compose stack for local development services
(PostgreSQL, Redis), with secrets templated via 1Password.

### Changes

**New files:**
- `docker/compose.yml` — plain compose file defining postgres and redis
  services with named volumes. Not templated — service selection can be done
  via profiles or conditional blocks later if needed.
- `docker/dot_env.tmpl` — chezmoi template that renders to `~/docker/.env`.
  Contains credentials fetched from 1Password at apply time. Compose reads
  this automatically.

**Modified files:**
- `.chezmoidata.toml` — added `dev_infra = ["mondo"]` host group for future
  per-machine conditional logic.
- `dot_aliases.tmpl` — added `infra` alias:
  `docker compose -f ~/docker/compose.yml` so you can run `infra up -d`,
  `infra logs postgres`, etc.

### Usage
```bash
# First time (requires 1Password session for .env):
chezmoi apply ~/docker/.env
# Then:
infra up -d          # start services
infra ps             # check status
infra logs -f postgres
infra down           # stop services
```

### Notes
- `compose.yml` is not templated, so `chezmoi apply ~/docker/compose.yml`
  works without 1Password.
- `~/docker/.env` requires an active 1Password session since it uses
  `onepasswordRead`.
- The `dev_infra` host group exists for future use — currently compose.yml
  is unconditional. To make services per-machine, either use compose profiles
  or convert `compose.yml` to `compose.yml.tmpl` with host group conditions.
- You'll need to create the `op://Private/local-postgres/password` item in
  1Password before applying.
