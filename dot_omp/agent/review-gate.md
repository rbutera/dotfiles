# Native cross-model review gate (omp)

Canonical delegation contract for omp. Every omp shadow skill points here
instead of restating it. Read this once per session; it is short on purpose.

## The rule

**Under omp, never call the harness-bridge MCP.** There is no `mcp__codex__*`
or `mcp__claude__*` tool here, and there does not need to be. omp has native
subagents that can each run on a different provider, which is exactly what the
bridge existed to fake.

Use the `task` tool with one of these agents:

| Agent  | Model                        | Use for |
|--------|------------------------------|---------|
| `codex` | `openai-codex/gpt-5.6-sol:high` | The Codex voice: independent cross-model review, implementation, second opinions |
| `opus`  | `anthropic/claude-opus-4-8:high` | The Opus voice: judgement calls, architecture critique, root-cause reasoning |

Both are defined in `~/.omp/agent/agents/`. Both have `bash`, so both can build,
test, and reproduce rather than reasoning from the diff alone.

## Translation table

Any instruction in a canonical skill body that says to use the bridge maps to a
`task` dispatch:

| Canonical skill says | Under omp, do this |
|---|---|
| `mcp__codex__codex_review_code` | `task` → agent `codex`, task = review this diff/target |
| `mcp__codex__codex_review_plan` | `task` → agent `codex`, task = critique this plan |
| `mcp__codex__codex_explain_code` | `task` → agent `codex`, task = explain this code |
| `mcp__codex__codex_plan_perf` | `task` → agent `codex`, task = performance analysis |
| `mcp__codex__codex_implement` | `task` → agent `codex`, task = implement this |
| `mcp__codex__codex_query` | `task` → agent `codex`, task = the question |
| `mcp__claude__claude_review_code` | `task` → agent `opus`, task = review this diff/target |
| dispatch the `codex-teammate` agent | `task` → agent `codex` |
| "parallel Opus + Codex review" | one `task` call per agent, dispatched together |

## What changes, beyond the tool name

- **No `workingDirectory` argument.** Subagents inherit the session cwd. Run
  omp from the worktree you want reviewed. If you need a different directory,
  say so in the task text and let the agent `cd`.
- **No shared rolling session.** Each `task` dispatch is a fresh subagent with
  no memory of earlier waves. The bridge leaked prior context between calls;
  this does not. Where a skill relied on that continuity, restate the context
  in the task text.
- **No 80k output cap** and no need to scope the target to dodge it. Normal
  subagent limits apply instead.
- **Parallel is free.** Dispatch `codex` and `opus` in the same turn to get a
  genuine dual-model gate concurrently. `task.maxConcurrent` governs the cap.

## Verifying the gate actually ran cross-model

Both agents open with an identity line, `[codex / gpt-5.6-sol:high]` or
`[opus / claude-opus-4-8:high]`, and both are instructed to **refuse the task
outright** if they are not actually on that model.

Why this matters: **omp silently falls back to the parent session's model when a
pinned model has no working credentials.** Verified 2026-07-23: with Anthropic
unauthenticated, a dispatch to `opus` ran on the caller's own Codex model and
would have returned a confident review. Nothing in the tool result says so. A
"second opinion" that is your own model wearing a different name is a check that
cannot fail.

**So check the identity line every time.** If it is missing, or names a model
other than the one the agent is pinned to, or the agent replied `REFUSING:`,
the gate did not run. Report it as not-run. Never report a pass.

A refusal from `opus` means Anthropic is not authenticated in omp. The fix is
`omp auth-broker login anthropic` (Claude Pro/Max OAuth) and it is Rai's action
to take. Do not work around it by substituting another model, and do not
proceed on a single-model gate while calling it a dual-model one.
