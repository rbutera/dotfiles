# chronicler config changes log

## 2026-04-19 — Fix navi.md path in .chronicler.json template

### Problem

The `dot_chronicler.json.tmpl` template referenced `navi.md` at `~/navi/agents/navi.md` (derived from `$pluginRoot`), but the actual file lives at `~/dev/lumiere/apps/ark/plugin/agents/navi.md`.

### Solution

Added a dedicated `$naviAgentFile` variable pointing to the correct path and updated both `$agentSummaryContextFiles` and `$summaryContextFiles` lists to use it instead of `joinPath $pluginRoot "agents" "navi.md"`.
