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

Both agents are instructed to open with an identity line, `[codex /
gpt-5.6-sol:high]` or `[opus / claude-opus-4-8:high]`, and to say so plainly if
they are not on that model.

**Check it.** A review gate whose second opinion silently came from the same
model as the first is a check that cannot fail. If the identity line is missing
or reports a different model, treat the gate as not run and say so, rather than
reporting a pass.

If `opus` returns a 401 or an auth error, Anthropic is not authenticated in omp.
Fix it with `omp auth-broker login anthropic` (Claude Pro/Max OAuth), that is
Rai's action to take, not something to work around by quietly substituting
another model.
