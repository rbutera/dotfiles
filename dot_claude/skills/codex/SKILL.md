---
name: codex
description: Ask OpenAI Codex for a second opinion — code reviews, explanations, plan critiques, performance analysis, or general questions
argument-hint: "<task or question>"
allowed-tools: "Read, Glob, Grep, Bash, mcp__codex__codex_query, mcp__codex__codex_review_code, mcp__codex__codex_review_plan, mcp__codex__codex_explain_code, mcp__codex__codex_plan_perf, mcp__codex__codex_implement"
---

You are invoking Codex to get a second opinion. Route the user's request to the most appropriate Codex MCP tool.

This is the interactive, human-readable path — a person is asking directly and will read your reply, so you synthesize Codex's answer for them (see step 5). This differs from the `codex-teammate` agent, which orchestrators and `/wave` use instead: that agent is a faithful pass-through that returns Codex's raw output unmodified, with no synthesis.

## Tool Selection

Pick the best tool based on the user's request:

| Request Type                | Tool                             | Key Parameters                              |
| --------------------------- | -------------------------------- | ------------------------------------------- |
| Code review, diff review    | `mcp__codex__codex_review_code`  | `target` (diff range or file), `focusAreas` |
| Plan critique               | `mcp__codex__codex_review_plan`  | `plan`, `codebasePath`                      |
| Explain code                | `mcp__codex__codex_explain_code` | `target` (file/function), `depth`           |
| Performance analysis        | `mcp__codex__codex_plan_perf`    | `target`, `metrics`                         |
| Implement/fix (writes code) | `mcp__codex__codex_implement`    | `task`                                      |
| General question            | `mcp__codex__codex_query`        | `prompt`                                    |

## Model rule (hard requirement)

**NEVER pass the `model` parameter on any `mcp__codex__*` call.** Omit it, always. When omitted, the bridge passes no `--model` flag and Codex CLI uses the default from `~/.codex/config.toml` (kept current: `gpt-5.6-sol`, high reasoning effort). The `model` enum in the tool schema can lag behind newly released models; picking from it silently downgrades the review. There is no situation where this skill should choose a model — if the user explicitly names one, pass exactly what they named, and only then.

## Execution

Codex runs unrestricted (harness-bridge's fixed execution contract), so it can run builds and tests to **verify its own findings**, and can commit inside a git worktree. There is no sandbox argument to set.

## Thread continuity rule

`threadKey` is optional and **omitted by default**, giving each call its own thread. Pass one only for a deliberate multi-turn conversation, never shared across concurrent calls.

## Instructions

1. Parse the user's argument to determine the task type
2. If the user references files, read them first for context
3. Call the most specific Codex tool — prefer specialized tools over `codex_query`
4. Always pass `workingDirectory` to every tool call
5. Synthesize the response: summarize key findings, highlight important points, give actionable recommendations
6. Only use `codex_implement` if the user explicitly asks Codex to make changes

## Examples

- `/codex review my recent changes` → `codex_review_code` with target "HEAD~1..HEAD"
- `/codex explain src/lib/exec.ts` → `codex_explain_code` with target "src/lib/exec.ts"
- `/codex is my approach to caching correct?` → `codex_query` with the question
- `/codex optimize the response parsing` → `codex_plan_perf` with target
- `/codex implement error handling for timeouts` → `codex_implement` with task
