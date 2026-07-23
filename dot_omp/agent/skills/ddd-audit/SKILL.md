---
name: ddd-audit
description: Dual-agent DDD convention scan using omp's native subagents. Dispatches opus + codex in parallel to audit code against D1-D5 conventions, anti-patterns, and layer rules. Synthesizes findings with disagreement flagging. Use when reviewing a PR, before pushing domain changes, before a push check, or standalone for a DDD health check. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# DDD Audit (omp)

This is the omp-native `ddd-audit`. It shadows the Claude Code copy (dispatches
two parallel agents via `/delegate`) and the `.agents` copy (a Codex
self-audit plus a cross-model Claude pass through the bridge). **omp has
neither `/delegate` nor a bridge**, both legs become plain `task` dispatches
to the two native subagents, run together.

## Step 1: read the canonical procedure

Read the full procedure from:

```
~/.claude/skills/ddd-audit/SKILL.md
```

Everything in that file applies:
scope determination (Phase 1), loading the DDD Playbook (Phase 2), the
synthesis/dedup/disagreement-flagging rules (Phase 4), and the pre-push /
review-mode integration points. **Except** the dispatch mechanism in Phase 3,
which is replaced below. Ignore the `/delegate` framing and the `.agents`
copy's bridge call (`mcp__claude__claude_query`) entirely, neither exists here.

## Step 2: the dual-agent dispatch is native here

Read `~/.omp/agent/review-gate.md` for the full delegation contract. In short,
per audit run, dispatch both agents with the `task` tool in the same turn:

- agent `opus`, the "Claude Agent Prompt" from the canonical file's Phase 3,
  verbatim (playbook sections + code to audit + codebase context).
- agent `codex`, the "Codex Teammate Prompt" from the canonical file's Phase
  3, verbatim.

Both get the same diff/files determined in Phase 1 and the same playbook
sections extracted in Phase 2. Both have `bash`, so both can read surrounding
code rather than judging from a pasted diff alone.

## Step 3: prove the audit was actually cross-model

Both agents open with an identity line: `[opus / <provider>/<model>]` or
`[codex / <provider>/<model>]`. Before writing the synthesis, confirm you saw
both lines and that they name two different models, an audit where both
"perspectives" came from one model is a check that cannot fail, and the
canonical file's whole point is disagreement flagging between two independent
models. Report it as not-run, not as agreement, if either is missing.

If `opus` returns an auth error, Anthropic is not authenticated in omp. Say so
and stop rather than quietly running a single-model audit. Fix:
`omp auth-broker login anthropic`, Rai's to run.

## What is different from the canonical versions

- No `/delegate` call, no bridge, no rolling shared session. Each `task`
  dispatch is a cold subagent, paste the full playbook sections and code
  into each prompt rather than assuming context carries over.
- No 80k output cap and no `workingDirectory` argument; subagents inherit the
  session cwd, so run omp from the worktree or repo you're auditing.
- The `.agents` copy's "Codex self-audit in-session, then bridge in a Claude
  pass" shape is superseded: both passes are equally native subagent
  dispatches here, so there's no reason to treat one as in-session and the
  other as remote. Dispatch both the same way, in parallel.
- Everything downstream (synthesis, `[DISPUTED]` flagging, severity ranking,
  pre-push/review-mode integration, handoff to `ddd-fix`) is unchanged.
