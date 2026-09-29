---
name: agent-model
description: Show which models the omp `codex` and `opus` review subagents are currently running on, list what is actually available to switch to, and set a per-agent override once Rai picks one. Use when Rai says "agent-model", "which model is codex on", "switch codex to terra", "change the opus model", "pick a model for the reviewer", or wants to see or change what a review subagent runs on. omp-only: it configures native subagents, there is no MCP bridge involved.
---

# agent-model

Show, then change, which model each review subagent runs on.

The `codex` agent uses the floating `openai-codex/sol:high` pattern. The `opus`
agent is deliberately pinned to `anthropic/claude-opus-4-8:high` to avoid
silently moving to a more quota-expensive release. This skill is for when Rai
wants a different model temporarily: another GPT variant, a newer Opus, or a
cheaper model for a throwaway pass.

## How the override works

`task.agentModelOverrides` is a record keyed by agent name. omp resolves it
**before** the agent file's own `model:`, so setting it retargets an agent
without editing its definition, and clearing it restores that agent's managed
default.

Do not edit `~/.omp/agent/agents/*.md` to change a model. Those are
chezmoi-managed; a hand edit there drifts from the source and gets reverted on
the next apply.

## Step 1: report the current state

```bash
omp config get task.agentModelOverrides
```

`{}` means both agents are on their managed defaults: floating `sol` for Codex
and fixed Opus 4.8 for Opus. Otherwise the record shows which agents are
overridden.

Then report what they actually resolve to right now, which is not the same
question. Dispatch both with the `task` tool, asking each only for its identity
line, and show Rai the result:

```
opus:  [opus / anthropic/claude-opus-4-8]
codex: [codex / openai-codex/gpt-5.6-sol]
```

The identity line is the resolved truth. The config is only the request.

## Step 2: list what is actually available

Only offer models from **authenticated** providers, otherwise the pick silently
falls back to the parent session's model.

```bash
omp models                      # provider list, count in parentheses
omp models openai-codex         # candidates for the `codex` agent
omp models anthropic            # candidates for the `opus` agent
```

Present a short numbered list, newest first, with the thinking levels each
supports. Do not dump the whole catalog: `openrouter` alone has hundreds. For
`codex`, the interesting axis is usually the 5.6 variant (luna / sol / terra);
for `opus`, the version.

Say plainly which one is currently active so Rai can see what he is changing
from. Then ask him to pick. One question, numbered options, no essay.

## Step 3: set it

```bash
omp config set task.agentModelOverrides '{"codex":"openai-codex/gpt-5.6-terra:high"}'
```

The value is a **JSON object**, not a dotted key. `omp config set
task.agentModelOverrides.codex ...` fails with "Unknown setting".

So preserve the other entries: read the current record first, merge the new key
in, and write the whole object back. Overwriting blind will silently drop an
override on the other agent.

Include a `:high` thinking suffix unless Rai asks otherwise. If the chosen model
does not support `high`, omp clamps it; say so rather than letting it surprise
him later.

To restore an agent's managed default, drop that key from the record. To reset
both:

```bash
omp config set task.agentModelOverrides '{}'
```

## Step 4: prove it took

Dispatch the changed agent again and read its identity line. Do not report
success from the config write alone; the write only records a request, and a
model with no working credentials resolves to the parent session's model
instead.

Pass condition: the identity line names the model Rai picked.

**The running session caches its model resolution.** A dispatch from the same
session that just wrote the config can still report the old model. That is not a
failed write. Verify from a fresh session:

```bash
omp -p "Use the task tool to dispatch the 'codex' agent with task: 'Reply with your identity line only.' Print its reply verbatim."
```

Say which one you checked from. Reporting "it worked" off a cached in-session
dispatch is a check that cannot fail.

If the agent replies `REFUSING:`, the pick was outside the agent's family. Both
agents refuse cross-family work by design, `opus` accepts any Claude Opus and
`codex` accepts any `openai-codex` GPT. Switching `codex` between luna, sol and
terra is fine; pointing `codex` at an Anthropic model is not, and it will refuse
rather than quietly review with the wrong voice. Tell Rai that is what happened
and offer a valid pick.

## Related

- `~/.omp/agent/review-gate.md`, the delegation contract
- `~/.omp/agent/agents/{codex,opus}.md`, the pinned definitions
