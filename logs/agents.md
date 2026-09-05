# Agent runtime config

## 2026-09-05: vendor Matt Pocock skills for shared agent discovery

**Problem/motivation:** Rai wanted the skills and their associated scripts copied
into chezmoi and shared across machines through `~/.agents/skills`, without plugins.

**Changes:** Imported all 37 skills and their complete resources from upstream
commit `3cca18b368ae95cdbdebbff572ccafa662551015`, retaining the MIT license.
Renamed the conflicting `tdd` and `teach` skills to `matt-tdd` and `matt-teach`
and updated invocation references and display names. Added a manual Python refresh
helper and provenance/hash manifest under `docs/matt-pocock-skills`; refreshes
refuse to overwrite local modifications. Executable resources retain their modes
through chezmoi source naming. Deployment uses a targeted files/directories-only
apply, avoiding bootstrap scripts and unrelated 1Password templates.

Dated changelog for Ark agent runtime configuration managed through chezmoi
(main-session models, ark.json templates, fleet toggles).

## 2026-08-05: fleet model toggle + revert to Opus 4.8 1M

Rai hit usage-quota pressure on both accounts with the mains on fable (set as the
default last week), and asked for that to become a proper toggle plus an immediate
revert. Changes:

- `.chezmoidata.toml`: new `[agents].main_model`, the single source of truth for the
  main-session model on both machines (Florence on kinto, Navi on nimbus).
- `focused/ark.json.tmpl` and `navi/ark.json.tmpl`: `"model"` now reads that value
  instead of a hardcoded string.
- `bin/executable_agent-model`: `agent-model fable|opus|show` edits the data value,
  applies locally, and commits and pushes the source so the other machine picks it
  up on its next `chezmoi update`. Takes effect on the NEXT ark session start;
  running sessions keep their model until restarted.
- Set to `claude-opus-4-8[1m]` (1M-context Opus 4.8; model string verified live on
  kinto before wiring: `claude --model "claude-opus-4-8[1m]" -p` returned OK).

Gotcha hit during rollout: a full `chezmoi apply` stalls on the 1Password-templated
`.aider.conf.yml` when no interactive op session exists. Targeted applies
(`chezmoi apply ~/focused/ark.json ~/bin/agent-model`) dodge it; the same applies
on nimbus.

## 2026-08-05: pin OMP to Opus 4.8

**Problem/motivation:** OMP still opened sessions on Opus 5 and its `opus`
reviewer floated to the latest Opus, bypassing the fleet's quota-conscious 4.8
selection.

**Changes:** Pinned both OMP's default session role and native Opus reviewer to
`anthropic/claude-opus-4-8:high`. Updated the review-gate, wave, and model-control
guidance so they describe the fixed 4.8 default while preserving explicit
per-agent overrides.

## 2026-09-02: fleet main model -> Claude Fable 5.1

**Problem/motivation:** Rai asked for Navi (nimbus) and the other Ark agents
(Florence on kinto) to default to Claude Fable 5.1. The fleet had been sitting on
`claude-opus-4-8[1m]` since the Opus 5 rollback (commit c07e50b), and the
`agent-model fable` target still pointed at the older `claude-fable-5`.

**Changes:**

- `.chezmoidata.toml`: `[agents].main_model` `claude-opus-4-8[1m]` ->
  `claude-fable-5-1`. Verified live on nimbus first: `claude --model claude-fable-5-1
  -p ... --output-format json` reports `model=claude-fable-5-1`, `is_error=false`.
  (`claude-fable-5-1[1m]` also resolves, but Fable is 1M-context natively so the
  plain id is used.)
- `bin/executable_agent-model`: `fable` target -> `claude-fable-5-1`. Two latent
  bugs fixed while here: the `sed` used `\s`, which BSD sed does not support, so
  the script silently never edited the value on macOS; now `[[:space:]]`. And it
  ran a full `chezmoi apply`, which stalls on the 1Password-templated files without
  an op session (see 2026-08-05 entry); now applies only `~/navi/ark.json` and
  `~/focused/ark.json` where they exist.
- Applied `~/navi/ark.json`, `~/focused/ark.json`, `~/bin/agent-model` on nimbus.
- Ark side note: `resolveModelFamily` in `apps/ark/src/sensors.ts` maps fable to
  `unknown`, which falls back to the `opus` budget row, and the 1M tier is detected
  from `~/.claude/settings.json` (`claude-opus-4-8[1m]`), so context-pressure
  budgets are unchanged (700k on navi). If the Claude Code default ever drops its
  `[1m]` suffix, the tier detection falls to `standard` (150k) for a 1M model.
- Claude Code's own default (`dot_claude/modify_settings.json`) left on
  `claude-opus-4-8[1m]`; only the Ark agents changed.
- Takes effect on the NEXT ark session start / `ark restart`. Navi's live session
  (started ~19h before this change) keeps Opus 4.8 until restarted. kinto picks it
  up on `chezmoi update`.
