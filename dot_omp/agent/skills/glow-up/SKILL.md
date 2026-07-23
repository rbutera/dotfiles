---
name: glow-up
description: Brainstorm substantial improvements to a project via parallel multi-model agents, pick the top X (default 3) that will bring Rai the most joy, then autonomously propose and build them end-to-end. Use when Rai says "glow-up", "/glow-up", "glow up <project>", "make this project better", "level up X", "what should we build next for X", "brainstorm big improvements", or points at a codebase and wants ambitious new features or substantial reworks ideated, selected, and implemented. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# Glow-Up (omp)

This is the omp-native `glow-up`. It shadows the `~/focused` copy of this
skill, which fans out Stage 1's ideation agents through the `codex-teammate`
agent and Claude Code's `general-purpose` agent with `model: opus`. **omp has
no bridge and no `codex-teammate` agent**, both voices are native subagents
here, dispatched with the `task` tool.

## Step 1: read the canonical procedure

Read the full glow-up procedure from:

```
~/focused/.claude/skills/glow-up/SKILL.md
```

Everything in that file applies, the stages, the vault note format, the
selection rubric, the validation pass, `/opsx:propose`, `/wave`, the shipping
decision, **except** Stage 1's agent dispatch table, which is replaced below.

## Step 2: Stage 1 dispatch, native

Still four agents, one message, still 20 ideas total. Replace the table with:

| Agent   | Class            | Dispatch                        | Brief |
|---------|------------------|----------------------------------|-------|
| A-opus  | A: new features  | `task` → agent `opus`           | 5 ambitious **new feature** ideas |
| A-codex | A: new features  | `task` → agent `codex`          | 5 ambitious **new feature** ideas |
| B-opus  | B: reworks       | `task` → agent `opus`           | 5 substantial **rework/improvement** ideas |
| B-codex | B: reworks       | `task` → agent `codex`          | 5 substantial **rework/improvement** ideas |

Everything else about the brief (project grounding, class rule, theme framing,
who it's for, the output contract writing to the vault scratch file) is
unchanged from the canonical Stage 1.

No `workingDirectory` argument, both agents inherit the session cwd. No shared
rolling session, each of the four is a cold dispatch. Read the full delegation
contract at `~/.omp/agent/review-gate.md` if any of that is unclear.

## Step 3: prove the fan-out was actually cross-model

Both `opus` and `codex` open with an identity line: `[opus /
claude-opus-4-8:high]` or `[codex / gpt-5.6-sol:high]`. Before compiling Stage
2's vault note, confirm all four completions show the right identity for their
row. Class A or B "opus vs codex" ideation where both sides came from the same
model is a check that cannot fail, flag it rather than compiling it as if it
were a genuine two-model spread.

If `opus` returns an auth error, Anthropic is not authenticated in omp. Say so
and stop the fan-out rather than silently substituting `codex` for both rows.
The fix is `omp auth-broker login anthropic`, and it is Rai's to run.
