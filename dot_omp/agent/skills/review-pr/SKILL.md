---
name: review-pr
description: Structured GitHub PR review with worktree isolation, hypothesis-first context, parallel dual-model agent dispatch, and a running vault note that persists state across multi-day reviews. Use when Rai says "review PR <n>", "/review-pr", "look at Chris's PR", "let's review", or wants any structured PR review in autonomous, solo, or paired mode. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# review-pr (omp)

This is the omp-native `review-pr`. It shadows the Claude Code and `.agents`
copies of this skill, which route stage 04's dual-agent dispatch through the
harness-bridge MCP (`mcp__codex__*`) plus Claude Code's native `Agent` tool.
**omp has no bridge and no `Agent` tool**, dispatch both reviewer voices as
native subagents instead.

## Step 1: read the canonical procedure

Read the full review-pr procedure from:

```
~/focused/.claude/skills/review-pr/SKILL.md
```

Everything in that file and its `references/` tree applies, invocation, mode
selection, the stage pipeline, the running-note schema, the hard rules ,
**except** stage 04's dispatch mechanics. Those are replaced by Step 2.

Ignore these sections of
`~/focused/.claude/skills/review-pr/references/stages/04-agents.md`
specifically:
- "Claude Code agent brief", the block starting "Dispatched via `Agent` tool
  with `subagent_type: \"general-purpose\"`"
- "Codex agent brief", the block starting "Dispatched as the `codex-teammate`
  agent or via a direct `mcp__codex__*` call"

Everything else in that file still applies as written: the `codex_enabled`
decision logic, the anti-pattern/convention checklist assembly, the brief
CONTENTS (hypotheses, risks, checklist, output format), the parallel-dispatch
rule, and the failure modes.

## Step 2: the two review voices are native here

Read `~/.omp/agent/review-gate.md` for the full delegation contract. Dispatch
**both** reviewers with the `task` tool, in the same turn:

- agent `opus`, takes the "Claude Code agent brief" role (hypothesis
  disconfirmation, convention checklist, CLAUDE.md constraints)
- agent `codex`, takes the "Codex agent brief" role (independent bugs/edge
  cases, unrestricted build-and-test)

Use the exact brief CONTENT from 04-agents.md for each, just swap the dispatch
mechanism. Both agents write their findings to the SAME filenames the
canonical file specifies, `~/focused/vault/reviews/PR<N>-claude.md` (now the
`opus` voice) and `~/focused/vault/reviews/PR<N>-codex.md`, so stage 06
(synthesize), which is untouched, still finds them at the paths it expects.

## Step 3: prove the gate was actually cross-model

Both agents open with an identity line: `[opus / <provider>/<model>]` or
`[codex / <provider>/<model>]`. Before advancing to stage 06, confirm you saw
both lines naming two different models. A dual-model gate where both voices
came from the same model is a check that cannot fail, report it as not-run,
never as a pass.

If `opus` returns an auth error, Anthropic is not authenticated in omp. Say so
and stop; the fix is `omp auth-broker login anthropic`, and it is Rai's to
run, do not silently fall back to a single-model review.

## What is different from the bridge version

- No `workingDirectory` argument, run omp from the worktree stage 01 created.
- No shared rolling session between the two agents or across resumed reviews;
  restate the running note's Context/Prior-understanding sections in full each
  time, per the brief content in 04-agents.md.
- No 80k output cap on either voice.
