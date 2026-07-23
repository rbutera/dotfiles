---
name: interaction-test-plan
description: Generate a mandatory, exhaustive Interaction Test Plan for a UI ticket via a 6-lens dual-model parallel-agent brainstorm on omp's native subagents (opus + codex), deduped into one scenario matrix + performance budget + derived-data dependency map. Use when the user says "interaction test plan", "test plan for FUS-XXX", "monkey-test scenarios", "/interaction-test-plan", or when ticket-to-spec / opsx:continue generates design.md for a non-trivial ticket that introduces a NEW user-facing UI element / component / view. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# Interaction Test Plan (omp)

This is the omp-native `interaction-test-plan`. It shadows the Claude Code
copy (12 agents: 6 lenses on Sonnet + 6 on Codex via `codex-teammate`, hard
pre-wave gate) and the `.agents` copy (Codex native + a cross-model Claude
pass via the bridge, and, note the drift, reframed as optional/never
auto-fired). **Treat the Claude Code copy as authoritative**: this plan is
mandatory per Rai's 2026-06-17 decision and the pre-wave gate in
`reviewed-implementation` depends on it. The `.agents` copy's "optional, never
auto-fire" framing is a divergence to flag, not to adopt.

## Step 1: read the canonical procedure

Read the full procedure, in full, from:

```
~/.claude/skills/interaction-test-plan/SKILL.md
~/.claude/skills/interaction-test-plan/references/lenses.md
~/.claude/skills/interaction-test-plan/references/dedup.md
```

Everything applies as written: Phase 1 context-gathering, the six lens
definitions, the mandatory `(E-primary)` spine row, the `(U)/(E)/(M)` coverage
discipline, Phase 4's write-into-`design.md` step, and the handoff to
`e2e-author` / `qa-gate`. **Except** the Phase 2 dispatch mechanism, which is
replaced below, omp has no Sonnet subagent option and no bridge.

## Step 2: the 12-way fan-out on native subagents

omp only defines two native subagents, `codex` and `opus`
(`~/.omp/agent/agents/`). Map both legs of the dual-model fan-out onto them:

- **6 lens dispatches** → agent `opus`, one `task` call per lens, using the
  Opus-flavoured lens prompt from `references/lenses.md`.
- **6 lens dispatches** → agent `codex`, one `task` call per lens, using the
  Codex-variant prompt at the bottom of `references/lenses.md`.

Dispatch all 12 in the same turn (`superpowers:dispatching-parallel-agents`
applies here same as always). Read-only, no worktree isolation needed. Each
returns the same flat row schema the canonical file specifies:
`scenario | other-elements-involved | expected | coverage (U/E/M)`.

If either native agent is unavailable, degrade to the other and say so in the
final report, never silently block the whole plan on one being down.

Phases 3-4 (dedup, the mandatory `(E-primary)` spine row, the coverage caps,
writing the section into `design.md`) are orchestrator work in the canonical
file too, not a subagent dispatch. Do them yourself, in-session, exactly as
`references/dedup.md` specifies, no native-agent mapping needed there.

## Step 3: prove the fan-out was actually cross-model

Both `opus` and `codex` open with an identity line, `[opus /
claude-opus-4-8:high]` or `[codex / gpt-5.6-sol:high]`. Before reporting the
plan as generated, spot-check that both appear across the 12 dispatches, a
"dual-model" fan-out where every lens actually came back from one model is a
check that cannot fail, and the entire point of running 12 agents is that the
two models' blind spots don't overlap. If `opus` 401s, degrade to
Codex-only per Step 2 and say so plainly; the fix (`omp auth-broker login
anthropic`) is Rai's to run, not something to route around silently.

## `workflow.js` verdict, no change needed

`~/.claude/skills/interaction-test-plan/workflow.js` is a Claude Code
**workflow script** (`agent()`/`parallel()`/`phase()` helpers, `agentType:
'codex-teammate'`). omp has no workflow-runner equivalent, so it is never
executed under omp regardless of its bridge-flavoured agent types, it isn't
a live dependency here, just a Claude Code-only orchestration layer. Its own
SKILL.md says the same for its own harness: until a workflow script lands,
"the skill's Phase 2/3 dispatch is the executable spec." Under omp, Step 2
above **is** that executable spec, permanently, nothing to port, nothing to
fix.

## What is different from the canonical version

- No Sonnet leg: omp's cheap-enumeration lens runs on `opus`, not a Sonnet
  subagent, because omp doesn't expose one. Accept the cost trade-off; do not
  substitute `codex` for both legs just to save cost, that defeats the
  dual-model point.
- No `codex-teammate` agentType, no bridge, no rolling session, each of the
  12 dispatches is a cold `task` call; paste full context into every prompt.
- Everything else, the mandatory gate, the lens prompts, dedup rules, and
  the `design.md` write target, is untouched.
