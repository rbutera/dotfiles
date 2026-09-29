---
name: pr-tend
description: Watch a single PR and respond to activity. Author mode fixes reviewer feedback, drafts replies, resolves threads, with a dual-model review of every fix before it's pushed. Reviewer mode tracks author responses and delta-reviews new commits. Use when the user says "tend PR", "watch PR", "pr-tend", "babysit this PR", or after /submit-pr or /review-pr completes. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# pr-tend (omp)

This is the omp-native `pr-tend`. It shadows the Claude Code and `.agents`
copies of this skill, which review each fix commit via Claude Code's native
`Agent` tool plus the `codex-teammate` bridge agent before pushing. **omp has
no bridge and no `Agent` tool**, dispatch both reviewer voices as native
subagents instead.

## Step 1: read the canonical procedure

Read the full pr-tend procedure from:

```
~/focused/.claude/skills/pr-tend/SKILL.md
```

Everything there applies as written, the router, the tending lease, role
detection, state file, scheduling. For author mode, also read
`~/focused/.claude/skills/pr-tend/references/author-mode.md` in full; it
applies **except** the "5. Dual-agent review the fix before pushing" section.

Ignore, specifically, this from `references/author-mode.md`:
- "**Agent 1 (Claude):**", the `Agent({ subagent_type: "general-purpose", ...`
  block
- "**Agent 2 (Codex):**", the `Agent({ subagent_type: "codex-teammate", ...`
  block

The surrounding rule stands unchanged: stage the fix (do not commit yet),
dispatch both reviewers on the staged diff before committing, skip this step
only for trivial fixes (typo, import order, whitespace).

## Step 2: the two review voices are native here

Read `~/.omp/agent/review-gate.md` for the full delegation contract. With the
fix staged (`git diff --cached`), dispatch both reviewers with the `task`
tool, in the same turn:

- agent `opus`, takes the "Agent 1 (Claude)" brief content verbatim
  (convention docs, DDD layer violations, minimal-and-scoped check)
- agent `codex`, takes the "Agent 2 (Codex)" brief content verbatim
  (correctness, edge cases, unintended side effects)

After both return: either flagging a real issue means fix it before
proceeding; disagreement means fix conservatively and note it in the report;
both clean means commit and push, exactly as the canonical file's "After both
return" logic says.

## Step 3: prove the gate was actually cross-model

Both agents open with an identity line: `[opus / <provider>/<model>]` or
`[codex / <provider>/<model>]`. Before committing on the strength of "both
clean," confirm you saw both lines naming two different models. A dual-model
review where both voices came from the same model is a check that cannot
fail, treat it as not-run and re-dispatch properly, don't push on it.

If `opus` returns an auth error, Anthropic is not authenticated in omp. Say so
and stop; the fix is `omp auth-broker login anthropic`, and it is Rai's to
run, do not silently push on a single-model review.

## What is different from the bridge version

- No `workingDirectory` argument, run omp from the PR's checked-out branch or
  worktree, per Step 3 of author-mode.md.
- No shared rolling session, each fix-review dispatch is a fresh subagent;
  restate the diff and the brief content in full every time.
- Everything else in `references/author-mode.md` (thread resolution, branch
  maintenance, merge handling, report format) is untouched.
