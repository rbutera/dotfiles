# Docker infrastructure changelog

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
