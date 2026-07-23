# pi / oh-my-pi (omp) changes log

## 2026-07-23 — Stop omp auto-enabling OpenRouter (377 models) and Bedrock (130)

### Problem

`omp`'s model picker listed **611 models across 7 providers**, of which
507 were OpenRouter (377) and AWS Bedrock (130) — neither of which Rai uses.
Sifting through them made model selection unusable.

Both were auto-enabled from ambient credentials, not from any omp config:

- **OpenRouter** — `omp` dotenv-loads **`$HOME/.env`** at startup. That file is
  chezmoi-managed (`dot_env.tmpl`, nominally an *aider* env file) and contained
  `OPENROUTER_API_KEY`. Confirmed empirically: `omp token openrouter` returned
  `sk-or-v1-10ac9…` (byte-identical to the `~/.env` line) even though the key is
  **not** exported in the login shell (`zsh -lc 'env | grep OPENROUTER'` → empty)
  and **not** in omp's own vault (`auth_credentials` in `~/.omp/agent/agent.db`
  holds only `anthropic`, `openai-codex`). Running with `HOME=/tmp/omptest-home`
  made `omp token openrouter` return nothing — proving `$HOME/.env` is the source.
- **Bedrock** — `AWS_PROFILE=ej-dev` (exported by
  `dot_config/zsh/easyjet.zsh.tmpl:28`, needed for easyJet work) is enough for
  omp to enable the `amazon-bedrock` provider and pull its full 130-model catalog.

### Changes

1. **`~/.env` OpenRouter key is now opt-in, default off** (chezmoi):
   - **`.chezmoidata.toml`**: added `feature_flags.openrouter_api_key = false`
     and `host_groups.openrouter = []`.
   - **`dot_env.tmpl`**: `OPENROUTER_API_KEY` wrapped in
     `{{ if or .feature_flags.openrouter_api_key (has .chezmoi.hostname .host_groups.openrouter) }}`.
     The off-branch emits a commented placeholder plus re-enable instructions, and
     — because the `onepasswordRead` call now lives inside the `if` — renders with
     **no 1Password round-trip at all**. Mirrors the existing `shared_claude_oauth`
     flag pattern and the `ANTHROPIC_API_KEY` deliberate-omission comment already
     in that file.
   - To re-enable: flip the flag (fleet-wide) or add a hostname to
     `host_groups.openrouter` (per-machine), then `chezmoi apply ~/.env`.

2. **Bedrock disabled at the omp layer** — `AWS_PROFILE` can't be unset (work
   needs it), so used omp's own setting instead:
   ```
   omp config set disabledProviders '["amazon-bedrock"]'
   ```
   Note the value must be **JSON** — bare `omp config set disabledProviders
   amazon-bedrock` fails with `Error: Invalid array JSON`.

### omp provider-filtering reference (researched this session)

- **`disabledProviders`** (array of provider ids) — drops a provider entirely:
  no models in the picker, no `/login` entry, and (since a bug fix noted in the
  omp changelog) no background discovery probes for local providers
  (Ollama/llama.cpp/LM Studio). Stored in `~/.omp/agent/config.yml`; it's in
  `PATH_SCOPED_ARRAY_SETTINGS`, so it can also be scoped per project.
- **`enabledModels`** (array) — the inverse: an allowlist, if disabling whole
  providers is too coarse.
- **`modelProviderOrder`** (array) — ranks providers rather than hiding them.
- Provider ids come from the group headers in `omp models`.

### Verification

`chezmoi apply ~/.env` → key gone from the deployed file. Then:
`omp token openrouter` → `No active credential`, and `omp models` provider
counts went **`amazon-bedrock(130) groq(26) openai-codex(7) opencode-go(23)
opencode-zen(34) openrouter(377) zai(14)` → `groq(26) openai-codex(7)
opencode-go(23) opencode-zen(34) zai(14)`** — 611 models down to 104.

### Not done

`~/.omp/agent/config.yml` is **not** chezmoi-managed — omp writes to it itself
(`setupVersion`, `modelRoles`, theme…), so `disabledProviders` was set via the
CLI on this machine only. If the Bedrock noise shows up on kinto too, either
re-run the `omp config set` there or bring the file under a `modify_` script
(see logs/chezmoi-modify-scripts.md) rather than a plain managed file.

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
