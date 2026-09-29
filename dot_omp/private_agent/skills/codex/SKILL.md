---
name: codex
description: Ask OpenAI Codex for a second opinion, code reviews, plan critiques, code explanations, performance analysis, implementation, or general questions. Use when the user says "ask codex", "get a second opinion", "codex review this", "what does codex think", or wants an independent cross-model check on code, a plan, or a design decision. Runs omp-native: dispatches the opus and codex subagents, no MCP bridge.
---

# Codex (omp)

This is the omp-native `codex`. It shadows the Claude Code copy of this skill,
which routes everything through the harness-bridge MCP (`mcp__codex__*` tools).
**omp has no bridge and does not need one**, Codex is a native subagent here,
dispatched with the `task` tool.

## How to ask Codex something

Dispatch `task` → agent `codex` (`openai-codex/sol:high` (latest `sol` GPT)). Put the full
brief in the task text: what you want, the relevant files/paths, and any
convention docs it should judge against. `codex` has `bash`, so tell it to
build/run/test rather than reason from a diff alone whenever that's possible.

Map the old bridge intents to what goes in the task text:

| Old bridge tool             | Task text says                                                  |
|------------------------------|------------------------------------------------------------------|
| `codex_review_code`         | Review this diff/target: `<range or files>`. Focus on `<areas>`. |
| `codex_review_plan`         | Critique this plan against the codebase: `<plan text/path>`.     |
| `codex_explain_code`        | Explain this code: `<file/function>`, depth `<summary/deep>`.    |
| `codex_plan_perf`           | Performance analysis of `<target>`, metrics of interest `<...>`. |
| `codex_implement`           | Implement `<task>`. (Writes code, only when explicitly asked.)  |
| `codex_query`               | Just the question, verbatim.                                    |

No `workingDirectory` argument: `codex` inherits the session cwd, so run omp
from wherever you want it looking. No shared rolling session either, each
dispatch is a cold subagent, so restate context rather than assuming it
remembers an earlier call.

## Synthesize, don't just relay

This is the interactive path, a person asked directly. Read `codex`'s full
reply, then summarize the key findings, highlight what matters, and give
actionable next steps. Only skip synthesis if the user explicitly wants the
raw output.

## Prove it was actually Codex

`codex` opens with an identity line: `[codex / <provider>/<model>]`. Before
reporting its answer as a genuine second opinion, confirm that line is there
and names that model. A "second opinion" that silently came from the same
model already answering is a check that cannot fail, report it as not run, not
as a pass.

If the dispatch errors out with an auth failure, say so and stop rather than
quietly answering the question yourself. Auth issues for `codex` are Rai's to
fix, not to be worked around.
