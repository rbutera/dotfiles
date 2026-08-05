# Agent runtime config

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
