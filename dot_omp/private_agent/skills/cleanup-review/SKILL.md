---
name: cleanup-review
description: Trio code-cleanup gate run before /qa-gate and /submit-pr. Finds behaviour-neutral simplifications (reuse, simplification, efficiency, altitude, dead code, duplication, convention drift) in the PR's own diff, verifies every contested claim against the compiler/tests/grep, applies the safe consensus, runs full gates, then re-verifies the cleanup didn't change behaviour. Use when Rai says "cleanup review", "/cleanup-review", "tidy pass", "simplification pass", "clean up the diff before submitting", or auto-fired as the first step of /submit-pr on a non-trivial diff. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# cleanup-review (omp)

This is the omp-native `cleanup-review`. It shadows the Claude Code and
`.agents` copies of this skill, whose trio (rick + Opus + Codex) is dispatched
via a Claude Code custom agent (`rick`), the native `Agent` tool, and the
`codex-teammate` bridge agent. **omp has no bridge, no `Agent` tool, and no
`rick` agent**, two of the three legs become native subagents; the third has
no native equivalent and is downgraded, explicitly, to self-review.

## Step 1: read the canonical procedure

Read the full cleanup-review procedure from:

```
~/focused/.claude/skills/cleanup-review/SKILL.md
```

Phases 0, 0.5, 2, 3, and 4's gate logic apply unchanged. Also read
`~/focused/.claude/skills/cleanup-review/references/reviewer-prompts.md` in
full; its shared preamble, the eight-lens catalogue, and the Pass 1/Pass 2
questions apply **except** the "Roles" dispatch mechanics.

Ignore, specifically, these lines from `references/reviewer-prompts.md`:
- "**rick** (`subagent_type: rick`)", no native equivalent, see Step 2 below
- "**Opus** (`subagent_type: general-purpose`, `model: opus`)"
- "**Codex** (`subagent_type: codex-teammate`)"

## Step 2: two legs are native, one leg has no native equivalent

Read `~/.omp/agent/review-gate.md` for the delegation contract that covers the
Opus and Codex legs. Pass 1 (find the cleanups) becomes:

- **rick's lens, downgraded to self-review.** omp has no `rick` agent. Do NOT
  invent a third `task` dispatch to fake it. Instead, run the minimality/YAGNI/
  deletion lens yourself, inline, against the same scope and convention docs,
  BEFORE dispatching the other two. Write it to
  `vault/reviews/<branch>-cleanup-rick.md` as usual, but head the file with a
  one-line disclosure: "Self-reviewed by the orchestrating agent; omp has no
  native rick equivalent." Never present this leg as an independent voice.
- **Opus leg**, `task` → agent `opus`, brief = rick's role's sibling content
  (elegance, whole-flow shape, correctness-of-the-simplification) from the
  shared preamble and Pass 1 question.
- **Codex leg**, `task` → agent `codex`, brief = the Codex role's content
  (independent engine, all eight lenses).

Dispatch `opus` and `codex` together in one turn; do the rick self-review
either before or after, it has no concurrency to gain.

Pass 2 (verify the applied cleanup) is **Opus + Codex only**, the canonical
file already makes rick optional there, and omp has no rick to include even
optionally. Dispatch both via `task` as above, same as a native dual-model
gate.

## Step 3: prove the two native legs were actually cross-model

`opus` and `codex` open with an identity line: `[opus / <provider>/<model>]`
or `[codex / <provider>/<model>]`. Before treating Pass 1 or Pass 2 as complete,
confirm both lines appeared and name two different models. A gate where both
native voices came from the same model is a check that cannot fail, report
it as not-run, not as a pass. The rick self-review leg is never counted toward
this cross-model claim; it's disclosed as self-review precisely so it isn't
mistaken for a third independent voice.

If `opus` returns an auth error, Anthropic is not authenticated in omp. Say so
and stop; the fix is `omp auth-broker login anthropic`, and it is Rai's to
run, do not quietly proceed on Codex + self-review alone and call it the
trio.

## What is different from the bridge version

- No `workingDirectory` argument, run omp from the worktree being cleaned up.
- No shared rolling session between Pass 1 and Pass 2; restate scope and
  convention docs in full each time.
- Everything in Phases 0/0.5/2/3/4 of the canonical `SKILL.md`, and
  `references/synthesis.md` / `references/state-contract.md`, is untouched.
