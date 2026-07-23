#!/usr/bin/env python3
"""
PreToolUse hook on the Agent tool: append the delivery rule to every background
subagent dispatch, so no prompt author has to remember it.

WHY THIS EXISTS
---------------
A background subagent ends its turn IDLE (alive, awaiting input), not COMPLETE.
Nothing it merely *says* becomes a return value, so a report written as its final
assistant message never reaches the dispatcher, which sees silence.

Measured 2026-07-23: six of six background agents, across Sonnet and Opus,
implementers and reviewers, finished their work and left the report sitting in
their own transcript. Every one had to be explicitly asked for it. One held a
complete code review for 35 minutes while the orchestrator diagnosed a transport
failure that had not happened.

Two stopgaps existed before this hook: prose in ~/.claude/agents/codex-teammate.md,
and a requirement in ~/focused/.claude/skills/reviewed-implementation/SKILL.md that
dispatch prompts carry the instruction. Both depend on whoever writes the prompt
remembering. A rule you have to remember is a rule that eventually fails (the Brita
Filter Rule), so this moves it into the dispatch path itself: it fires on the Agent
tool call regardless of which agent definition is used, including the built-ins,
and regardless of what the dispatching prompt says.

THE PRECISE RULE
----------------
Inject only when the agent will actually end up idle:
  - run_in_background is explicitly false  -> SKIP. A synchronous agent's final
    message IS returned to the caller; telling it to SendMessage adds noise and a
    duplicate report.
  - the prompt already mentions SendMessage -> SKIP. The author handled it; a
    second copy is just contradiction risk.
  - otherwise (background is the Agent tool's default) -> APPEND.

CONTRACT
--------
PreToolUse hook. stdin = {"tool_name", "tool_input", ...}.
stdout = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "updatedInput": {...}}}
`updatedInput` replaces the tool input wholesale, so the whole dict is echoed back
with only `prompt` changed. Verified 2026-07-23 against Claude Code 2.1.218 that
`updatedInput` is applied WITHOUT also setting permissionDecision, so this hook
does not touch permissions.

FAIL-OPEN, ALWAYS. Emitting nothing and exiting 0 leaves the dispatch untouched.
A broken hook here must never be able to block agent dispatch.

ADMISSION TEST FOR ANYTHING YOU WANT TO ADD TO THIS PAYLOAD
-----------------------------------------------------------
Inject only what is true for EVERY background agent regardless of what it was
asked to do. The delivery rule qualifies because it is context-free: "your last
action must be a SendMessage" is correct for a reviewer, a researcher, an
implementer and a one-line probe alike.

Anything whose correctness depends on the task belongs in the dispatch prompt,
not here. Worked example, decided 2026-07-23: "announce when you START" was
proposed and rejected. It only pays when the agent owns a mutable resource the
dispatcher might touch, and this hook cannot know that, so injecting it
unconditionally would make it wrong most of the times it fires. A rule that is
usually wrong gets ignored on the occasions it is right, which is worse than not
having it.

That is the real risk here: a payload that accretes becomes a payload agents
skim past, which would silently un-fix the exact bug this hook fixes, and would
do it invisibly.

"""
import json
import sys

DELIVERY_RULE = """

---

## Delivery rule (appended automatically — non-negotiable)

**Your last action MUST be a `SendMessage` call to the agent that dispatched you, carrying your actual report.** A final assistant message is NOT delivery.

You were dispatched as a background teammate, so you end your turn **idle** (alive, awaiting input), not **complete**. Nothing you merely *say* becomes a return value: your dispatcher receives silence and has to come and ask you for work you already finished.

So:

1. Do the work.
2. **`SendMessage` the result to your dispatcher** — its name is in your teammate list; the main conversation is `main`. Send the real content: findings, file paths, the verdict. Not "done, see above", which is exactly the failure this rule exists to stop.
3. Only then end your turn.

This applies to failure too. `BLOCKED: <reason>` must be **sent**, not merely stated — a dispatcher who hears nothing cannot tell a blocked agent from a slow one, and will waste time diagnosing the wrong thing. If the report is too large for one message, send it in ordered parts and say so; do not summarise it away to fit.
"""


def main() -> None:
    payload = json.load(sys.stdin)

    if payload.get("tool_name") != "Agent":
        return

    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return

    prompt = tool_input.get("prompt")
    if not isinstance(prompt, str) or not prompt.strip():
        return

    # Synchronous agents return their final message normally — nothing to fix.
    if tool_input.get("run_in_background") is False:
        return

    # The dispatching prompt already carries the rule; don't say it twice.
    if "SendMessage" in prompt:
        return

    updated = dict(tool_input)
    updated["prompt"] = prompt + DELIVERY_RULE

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "updatedInput": updated,
        },
        "suppressOutput": True,
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Fail open. Never block a dispatch because this hook had a bad day.
        pass
    sys.exit(0)
