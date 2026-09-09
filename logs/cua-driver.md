# cua-driver changes log

## 2026-09-09 — Set up cua-driver (Cua computer-use MCP) for Claude Code on macOS

### Motivation
Rai wanted cua-driver (trycua/cua, Rust computer-use driver with an MCP server)
working for Claude. The binary and the `~/.claude.json` MCP entry
(`~/.local/bin/cua-driver mcp`) already existed, but every MCP tool returned
`permissions_pending`: macOS Accessibility / Screen Recording had never been
granted to the CuaDriver app.

### What was done (machine state, not tracked in this repo)
- `cua-driver update --apply` — 0.24.0 → 0.25.0. Binary lives in
  `/Applications/CuaDriver.app`, symlinked from `~/.local/bin/cua-driver`.
- `cua-driver skills install` — skill pack at `~/.cua-driver/skills/cua-driver`,
  symlinked into `~/.claude/skills/cua-driver` (plus Codex, OpenCode, Hermes).
- Granted Accessibility + Screen Recording to **CuaDriver.app** in System
  Settings. `cua-driver call health_report '{}'` → overall `ok`.

### Gotchas learned
- **TCC attribution.** Grants attach to the app identity `com.trycua.driver`,
  NOT the terminal. Starting the daemon with a bare `cua-driver serve` from an
  agent/IDE shell gives it the terminal's identity, and permission prompts then
  land on the wrong process. Always start it with
  `open -n -g -a CuaDriver --args serve` (or let `cua-driver mcp` spawn it).
- `cua-driver permissions status` reports `unknown` unless an app-bundle daemon
  is running; that is not "denied".
- If the prompts were approved but the daemon still reports missing grants,
  check System Settings → Privacy & Security → Accessibility / Screen & System
  Audio Recording for a CuaDriver entry and toggle it on, then restart the daemon.
- ffmpeg is not needed on macOS (recording uses ScreenCaptureKit).
- Config: `~/.cua-driver/config.json` (telemetry disabled). Update with
  `cua-driver update --apply`; `cua-driver doctor` for diagnostics.
