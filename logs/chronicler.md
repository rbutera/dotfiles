# chronicler config changes log

## 2026-10-17 — Model to gpt-6-astra (silent 3-day outage)

### Motivation

From 14 Oct afternoon the ChatGPT Codex backend returned HTTP 400 "The 'gpt-5.5' model is not supported when using Codex with a ChatGPT account" on every request. The hourly job still exited 0, so no day files appeared for 15 to 17 Oct (bead workspace-y1b7g).

### Changes

- **`dot_chronicler.json.tmpl`**: model `openai-codex/gpt-5.5` -> `openai-codex/gpt-6-astra` (the model `~/.codex/config.toml` uses). Paired with lumiere 241a9d5f, which registers the model in openai-json routing, fixes the EXDEV profile sync, and makes the wrapper exit non-zero on failure.

## 2026-04-26 — Bump chronicler model to gpt-5.5

### Changes

- **`dot_chronicler.json.tmpl`**: Updated model from `openai-codex/gpt-5.4` to `openai-codex/gpt-5.5`, aligning with the Codex CLI model bump from 2026-04-24.

## 2026-04-19 — Fix navi.md path in .chronicler.json template

### Problem

The `dot_chronicler.json.tmpl` template referenced `navi.md` at `~/navi/agents/navi.md` (derived from `$pluginRoot`), but the actual file lives at `~/dev/lumiere/apps/ark/plugin/agents/navi.md`.

### Solution

Added a dedicated `$naviAgentFile` variable pointing to the correct path and updated both `$agentSummaryContextFiles` and `$summaryContextFiles` lists to use it instead of `joinPath $pluginRoot "agents" "navi.md"`.
