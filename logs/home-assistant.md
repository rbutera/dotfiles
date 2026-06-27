# Home Assistant config changes log

## 2026-06-27 — Wire HASS_TOKEN + HASS_SERVER into the shell env (nimbus)

### Motivation
Home Assistant was deployed (dockerised) on nimbus and a long-lived API token
(~10 year lifespan) was minted to drive it programmatically. The token needs a
durable, secure home (1Password) and shell-wide availability so scripts and
agents can reach HA without a local token file.

### Changed
- `dot_config/zsh/host-infra.zsh.tmpl`: inside the `nimbus` host block, added:
  - `export HASS_SERVER="http://localhost:8123"`
  - `export HASS_TOKEN={{ onepasswordRead "op://Private/Home Assistant nimbus/credential" | quote }}`
- Depends on a 1Password item (vault `Private`, type API Credential, name
  `Home Assistant nimbus`, token in the `credential` field). Rai creates this item.

### Apply
`chezmoi apply ~/.config/zsh/host-infra.zsh` (requires an active 1Password session).
Renders to nothing on hosts other than nimbus (host-gated block).

### Notes
- The token also lives at `~/navi/.ha-tokens.json` (chmod 600, gitignored) which
  Navi's tooling currently reads; once it is in 1Password + the env, tooling can
  switch to `$HASS_TOKEN`.
- Full HA deployment writeup: `~/expedition/Home Assistant Deployment - Nimbus.md`.
