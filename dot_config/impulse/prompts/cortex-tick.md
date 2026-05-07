Read the do-tick skill at ~/dev/lumiere/apps/cortex-cc/skills/do-tick/SKILL.md and execute it exactly.

Report exactly one of these status codes as the last line of your output:
- TICK_IDLE — no work found
- TICK_COMPLETE — task claimed and completed
- TICK_HANDOFF — task claimed but handed off to another agent
- TICK_GATED — task found but blocked on a gate (Rai approval, missing input, etc.)
- TICK_ERROR — something went wrong
