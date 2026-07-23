---
name: wave
description: Implement tasks in waves with dual-model review gates, using omp's native subagents. Works with OpenSpec changes, structured plans, or any parseable task list. Implements each wave, then gates it with parallel Opus + Codex reviewers running on different providers, fix-loops until both pass, then proceeds. Use when the user says "wave", "implement with review", "reviewed implementation", or wants review-gated multi-phase implementation. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# Wave (omp)

This is the omp-native `wave`. It shadows the Claude Code and `.agents` copies
of this skill, which route their review gate through the harness-bridge MCP.
**omp has no bridge and does not need one**; it has native subagents that each
run on their own provider.

## Step 1: read the canonical procedure

Read the full wave procedure from:

```
~/.claude/skills/wave/SKILL.md
```

Everything in that file applies: how to find tasks, how to build dependency
waves, the fix-loop, the completion criteria. The one exception is any part
naming MCP tools or the `codex-teammate` agent; Step 2 replaces those.

Ignore these sections of the canonical file specifically:
- any instruction to call `mcp__codex__*` or `mcp__claude__*`
- the note about `codex-teammate` and the inline fallback
- the note about the bridge's "fixed execution contract"

## Step 2: the review gate is native here

Read `~/.omp/agent/review-gate.md` for the full delegation contract. In short:

Per wave, dispatch **both** reviewers with the `task` tool, in the same turn so
they run concurrently:

- agent `opus`, latest Claude Opus, high reasoning
- agent `codex`, latest OpenAI sol GPT, high reasoning

Give each the same brief: the wave's scope, the changed paths, the conventions
they must judge against, and an explicit instruction to build and test rather
than review from the diff alone. Both have `bash`.

The gate passes only when **both** reviewers pass. One pass plus one fail is a
fail: fix and re-run the gate.

## Step 3: prove the gate was actually cross-model

Both agents open with an identity line: `[opus / <provider>/<model>]` or
`[codex / <provider>/<model>]`.

Before reporting a wave as passed, confirm you saw both lines and that they
name two different models. A dual-model gate where both voices came from the
same model is a check that cannot fail, report it as not-run, not as a pass.

If `opus` returns an auth error, Anthropic is not authenticated in omp. Say so
and stop; do not silently continue with a single-model gate. The fix is
`omp auth-broker login anthropic`, and it is Rai's to run.

## What is different from the bridge version

- No `workingDirectory` argument, subagents inherit the session cwd, so run
  omp from the worktree you are implementing in.
- No rolling shared session between calls. Each wave's reviewers start cold.
  Restate the context each wave rather than assuming they remember the last.
- No 80k output cap, so no need to narrow `target` to dodge truncation.
