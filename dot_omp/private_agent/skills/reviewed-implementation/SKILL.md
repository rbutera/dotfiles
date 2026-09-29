---
name: reviewed-implementation
description: Fusion-specific wrapper for wave, using omp's native subagents. Injects vault convention docs (anti-patterns, DDD, frontend conventions) then delegates to the omp-native wave shadow. Use when the user says "implement with review", "reviewed implementation", "apply with reviews", or when running opsx:apply on a multi-phase Fusion change. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# Reviewed Implementation (omp)

This is the omp-native `reviewed-implementation`. It shadows the Claude Code
and `.agents` copies, both of which assume a `rick` implementer persona and a
harness-bridge-backed review gate. **omp has neither**, no `rick` agent is
registered here, and there is no bridge.

## Step 1: read the canonical procedure

Read the full procedure from:

```
~/.claude/skills/reviewed-implementation/SKILL.md
```

Everything in that file applies as written: the convention-doc injection list,
the T5-T9 backend test-quality rules, the `## Interaction Test Plan` pre-wave
gate, the `openspec/` gitignore quirk and commit block, and the final
`/cleanup-review` handoff. **Except** the parts naming the `rick` agent type
and the bridge's execution contract, those are replaced below.

## Step 2: convention injection is unchanged

Read the same doc set the canonical file lists (`Fusion C# Anti-Patterns.md`,
`Fusion C# Team Conventions.md`, `Fusion Frontend Conventions.md`,
`openspec/config.yaml`, `fusion/CLAUDE.md`) before touching any code. Nothing
here is bridge- or agent-specific; do it exactly as written.

## Step 3: no native `rick`, implement in-session, minimality-first

omp only defines two native subagents, `codex` and `opus` (`~/.omp/agent/agents/`).
There is no `rick` persona to dispatch. Do the implementation **in the current
session**, not as a separate subagent, carrying rick's discipline inline:
reuse over rewrite, stdlib over new deps, smallest correct diff, one runnable
check left behind. Read the convention docs first regardless.

Do **not** spawn `codex` or `opus` as implementers here, they are reserved for
the review gate, and an implementer reviewing its own diff is the bias the
canonical file explicitly forbids.

## Step 4: the review gate is the omp `wave` shadow

Once a wave's implementation is committed, delegate the gate to:

```
~/.omp/agent/skills/wave/SKILL.md
```

That shadow already dispatches `opus` + `codex` in parallel via the `task`
tool and fix-loops until both pass. Give it the same wave scope, changed
paths, and convention docs you loaded in Step 2, it has no memory of this
session's earlier reads.

## Step 5: prove the gate was cross-model

Same rule as every omp shadow: both reviewers open with an identity line,
`[opus / <provider>/<model>]` or `[codex / <provider>/<model>]`. Confirm both
lines, from two different models, before reporting a wave as passed. If
`opus` 401s, say so and stop, the fix is `omp auth-broker login anthropic`,
Rai's to run, not a reason to silently gate on Codex alone.

## What is different from the canonical version

- No `rick` agentType, no `Agent` tool dispatch for the implementer, the
  orchestrating session does the implementation itself.
- No `mcp__codex__*` sandbox argument to worry about; the native `codex` agent
  already has unrestricted `bash`, so implement inside a `wt/` worktree same
  as before and let reviewers build/test to verify findings.
- Everything else, conventions, the Interaction Test Plan gate, the commit
  block, `/cleanup-review` as the next step, is untouched.
