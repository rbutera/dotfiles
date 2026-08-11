# Output styles

Changelog for the Claude Code output-style layer (rai-base / florence / navi).

## 2026-08-11 — Introduced rai-base + florence + navi output styles

**Motivation:** Rai wanted a conversational, ADHD-aware, proactive-execution voice across all machines, replacing per-agent voice blocks buried in the ark agent-definition files (florence.md/navi.md). Research (4 subagents, captured in `~/focused/vault/Output Styles Redesign.md`) settled: voice belongs in exactly one place, the output style; Claude Code output styles have no runtime inheritance, so per-agent files are composed from one shared core at build time; wiring is per-directory `outputStyle` in settings (project beats user by cwd); build on the built-in Proactive behavior with `keep-coding-instructions: true`.

**Changed:**
- Added `.chezmoitemplates/output-style-general` — the shared general core body (proactive execution, conversational-shape, ADHD-aware orientation, voice, when-to-expand override conditions).
- Added `dot_claude/output-styles/rai-base.md.tmpl`, `florence.md.tmpl`, `navi.md.tmpl` — each = its own frontmatter + `{{ includeTemplate "output-style-general" . }}` + (florence/navi) a voice delta. All `keep-coding-instructions: true`.
- `dot_claude/modify_settings.json` — added `outputStyle` to the managed base + a `.outputStyle = $base.outputStyle` line in the jq merge, pinning the user-level default to `rai-base` on all machines.

**Wiring:** rai-base = user default (~/.claude/settings.json, this repo). florence = ~/focused/.claude/settings.json (focused repo, not chezmoi). navi = ~/navi/.claude/settings.json (nimbus).

**Deployed on kinto** via targeted `chezmoi apply ~/.claude/output-styles ~/.claude/settings.json` (op-free, those paths have no secrets). Full `chezmoi apply` still needs a 1Password session.

**Verify gate (pending):** confirm a `claude --agent florence` session actually loads the outputStyle via `/context` before slimming the voice blocks out of the agent files (Phase 2).
