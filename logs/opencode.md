# opencode config changes log

## 2026-04-10 — Sync modify_oh-my-openagent.json with upstream

### Problem
Running `bunx install oh-my-openagent` updated the deployed
`~/.config/opencode/oh-my-openagent.json` with new fields (fallback_models on
most agents/categories, new `sisyphus-junior` agent). The chezmoi modify script
didn't have these fields, so the next `chezmoi apply` would strip them out.

### Solution

**`dot_config/opencode/modify_oh-my-openagent.json`**:
- Added `fallback_models` to agents: sisyphus, oracle, explore,
  multimodal-looker, prometheus, metis, momus, atlas
- Added new agent: `sisyphus-junior` (opencode-go/kimi-k2.5 with fallbacks)
- Added `fallback_models` to categories: ultrabrain, quick, unspecified-low,
  unspecified-high, writing
