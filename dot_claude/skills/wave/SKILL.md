---
name: wave
description: Implement tasks in waves with dual-agent review gates. Works with OpenSpec changes, structured plans, or any parseable task list. Dispatches implementation agents per wave, runs parallel review agents (Opus + Codex by default), fix loops until both pass, then proceeds to the next wave. Use when the user says "wave", "implement with review", "reviewed implementation", or wants review-gated multi-phase implementation.
allowed-tools: Agent, Bash, Read, Write, Edit
---

# Wave

Implement a set of tasks in waves with dual-agent review gates between each wave.

The pattern: parse tasks into dependency waves, dispatch implementation agents per wave, review each wave with parallel agents, fix issues, proceed.

## When to use

- Multi-phase implementation where each phase builds on the previous
- Any codebase where you want review gates between implementation phases
- When quality matters more than speed (client code, shared libraries, infra)

## Step 1: Find the tasks

Try sources in this order:

1. **OpenSpec change** (preferred): if the user names a change, or one is inferrable from context, run:
   ```bash
   openspec instructions apply --change "<name>" --json
   ```
   This gives you context files, progress, and task list. If `state: "blocked"`, tell the user artifacts are missing and suggest `/opsx:continue`. If `state: "all_done"`, suggest `/opsx:archive`.

2. **Plan file**: look for a `docs/superpowers/plans/*.md` or similar structured plan in the repo. Parse tasks from checkbox lists or numbered sections.

3. **Explicit task list**: the user gave you tasks directly (in conversation, a markdown file, a GitHub issue). Parse them.

If you can't find tasks from any source, ask: "I can't find a task list. Do you have an OpenSpec change, a plan file, or a list of tasks I should work from?"

Always announce what you're working from: "Using OpenSpec change: <name>" or "Using plan: <path>" or "Using tasks from conversation".

## Step 2: Discover conventions

Read the project's convention docs so implementation agents and reviewers know the rules:

1. Crawl all CLAUDE.md and AGENTS.md files in the project tree (root + nested dirs)
2. If OpenSpec is being used, read `openspec/config.yaml` for any `context` section
3. Check for a `.wave.yaml` in the project root (optional config, see below)

If the crawl finds no meaningful conventions (no CLAUDE.md, empty files, generic boilerplate), ask the user: "I didn't find clear conventions in this repo. Do you know if there's somewhere I can look to find conventions or rules for this project?"

Collect all convention doc paths. These get injected into every implementation and review agent prompt.

### Optional `.wave.yaml`

Projects can provide a config file for additional context:

```yaml
conventions:
  - path/to/extra-conventions.md
  - path/to/anti-patterns.md
verification:
  pre: "npm test"
  post: "npm run typecheck && npm run lint"
review:
  agents:
    - type: claude
      model: opus
    - type: codex
```

All fields optional. If absent, defaults apply (Opus + Codex review, no extra conventions, no verification commands).

## Step 3: Parse tasks into waves

Group tasks by dependencies:

- **Wave 1**: tasks with no dependencies on other tasks (run in parallel)
- **Wave 2**: tasks that depend on Wave 1 outputs
- **Wave N**: and so on

Heuristics for wave grouping:
- Backend tasks with no shared files = same wave (parallel)
- Frontend tasks depending on backend endpoints = later wave
- Integration/verification tasks = final wave
- If a task says "after X" or "depends on X", it goes in the wave after X

Display the wave plan before starting:
```
Wave 1 (parallel):
  - Task 1: ...
  - Task 2: ...
Wave 2 (after wave 1):
  - Task 3: ...
Wave 3 (final):
  - Task 4: ...
```

## Step 4: Implement each wave

For each wave:

### 4a. Dispatch implementation agents

One agent per independent task in the wave. Each agent prompt MUST include:

1. **Working directory**: the repo path (or worktree path if using one)
2. **Convention docs**: every path collected in Step 2. Tell agents: "Read these BEFORE writing code. These are hard constraints, not suggestions."
3. **Task description**: the full text of the task, not a summary
4. **Context files**: if OpenSpec, include proposal/design/specs. If a plan file, include it. If the task references specific files, list them.
5. **Commit rules**: commit after each logical unit, descriptive messages
6. **Output format**: report status as DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, list files changed, summarize what was built
7. **No self-orchestrated review (MANDATORY)**: every implementation-agent prompt MUST explicitly forbid the agent from spawning, dispatching, or SendMessage-ing its OWN review/verification subagents (no "dual review", no Opus/Codex reviewer, no self-review loop). The agent ONLY implements, runs the gate commands (build/test/lint/typecheck) itself, commits, and reports facts. **The orchestrator (you) owns the review gate — step 4c — always.** Rationale: a spawned implementation agent and the reviewers it spawns are separate sessions; the reviewers cannot SendMessage back to it, so the implementer hangs forever waiting on verdicts it can never receive. Put this prohibition in the prompt in plain terms, e.g. "⛔ Do NOT spawn any review subagents; implement + gate + commit + report only — the orchestrator reviews."

If using OpenSpec with a schema that has an apply instruction (like fusion-workflow), tell the agent to use `/opsx:apply`. Otherwise, the agent implements directly from the task description.

**Model selection for implementation:**
- **Sonnet**: straightforward tasks (CRUD, test writing, component creation, config changes)
- **Opus**: complex domain logic, refactoring existing code, architectural decisions, multi-file coordination

**Codex as the implementation agent.**

`mcp__codex__codex_implement` runs Codex unrestricted (harness-bridge's fixed execution contract), so it can commit inside a git worktree and run the full hosted test suite. There is no sandbox argument to set. Omit the `model` param too — omitting it lets `~/.codex/config.toml` win, and its model enum can lag.

Note the reason the test-count rule below exists: a sandboxed Codex used to **silently exclude the hosted tests it could not run** and report green off the remainder. The contract change removed that failure mode, but re-running the gates and asserting the count is still mandatory, because a claim is not evidence.

All independent tasks in a wave dispatch in a **single message** (parallel), and **ALWAYS with `run_in_background: true`** — never block the main session waiting on an agent. After dispatching, await each agent's completion notification, then proceed. Running in the background keeps the orchestrator responsive (e.g. to the user) while waves execute.

### 4b. Handle implementation results

- **DONE**: proceed to review
- **DONE_WITH_CONCERNS**: read concerns. If correctness/scope, address before review. If observational, note and proceed.
- **NEEDS_CONTEXT**: provide missing context, re-dispatch
- **BLOCKED**: assess. Context problem = provide context. Task too hard = re-dispatch with opus. Task too large = break it up. Plan wrong = ask the user.

### 4c. Review gate

**The orchestrator ALWAYS runs the review gate — never the implementation agent.** Implementation agents are forbidden from spawning their own reviewers (step 4a.7), because a spawned agent and the reviewers it spawns are separate sessions: the reviewers cannot report back to it, so it hangs waiting on verdicts it can never receive. So do NOT rely on any self-review an implementation agent claims — if an agent reports it "ran a dual review", treat that as a process violation, ignore its verdicts, and run the gate yourself on the committed diff. You dispatch the reviewers, you receive the verdicts, you decide.

Once the implementation agent reports DONE (with its gate output), dispatch **two review agents in parallel** yourself:

**Agent 1 (Claude Opus):**
- Read the diff: `git diff <base>..<head>`
- Read convention docs (same set as implementation agents)
- Read spec/plan context
- Focus: convention violations, architecture fit, test coverage, edge cases
- Verdict: PASS or FAIL with specific file:line references

**Agent 2 (Codex):**
- Dispatch this as the `codex-teammate` agent (`subagent_type: codex-teammate`). It runs Sonnet-low and relays the review task straight to a Codex MCP tool verbatim — it does not read files or form its own opinion first.
- Give it the same review **target** as Agent 1 — the diff range/commits (`<base>..<head>`) — plus any caller-known context **paths** (convention doc paths, spec/plan file paths), as a self-contained task description, since Codex can't see this conversation's history. Do **not** hand it Agent 1's operational instructions ("Read the diff", "Read convention docs", "Read spec/plan context") — the relay must not read anything itself; it passes the review task to Codex, which reads the actual content itself via `workingDirectory`.
- **Do not pass a spawn-time `model` override when dispatching this agent.** A spawn-time `model` beats the agent's own frontmatter (`model: sonnet`), which would force it onto Opus and silently re-break Codex's independence. Let the agent's own frontmatter apply.
- **Reviewers can build and test.** Codex runs unrestricted, so `mcp__codex__codex_review_code` can run a build or the suite to verify its own findings rather than reasoning from source alone. There is no sandbox argument.
- **Concurrency is safe by default.** Each call gets its own Codex thread unless you pass a `threadKey`, so parallel reviewers across waves and worktrees do not collide. Only pass a `threadKey` when you deliberately want a multi-turn conversation, and never share one key across concurrent callers.
- The inline fallback is permitted **only if the `codex-teammate` agent is genuinely unavailable**. Even then, it MUST hand the review instructions to a Codex MCP tool (e.g. `mcp__codex__codex_review_code`) verbatim, with `workingDirectory` set, and return Codex's raw verdict as-is — no reading files first, no Opus opinion layered on top.
- Independent second opinion — catches different things (naming, patterns, subtle bugs) precisely because it's Codex's read, not Opus's read of Codex.
- Verdict: PASS or FAIL with specific file:line references, reported as Codex gave them.

Both agents dispatch in a **single message** (parallel). Use `run_in_background: true`.

The review agent pair is configurable: if `.wave.yaml` specifies different agents, use those. Default: Opus + Codex.

### 4d. Synthesize reviews

- **Both PASS**: proceed to next wave
- **Both FAIL on same issue**: dispatch fix agent with the specific fix, then re-review
- **Disagree**: if the FAIL cites a specific convention rule, fix it. If subjective, proceed. If genuinely ambiguous, present to user.
- **One FAIL, one PASS**: read the FAIL. Convention violation = fix. Subjective = proceed.

If a review gate fails **twice on the same issue**, escalate to the user instead of looping.

### 4e. Mark progress

After a wave passes review:
- If OpenSpec: update task checkboxes in tasks.md (`- [ ]` to `- [x]`)
- If plan file: update checkboxes in the plan
- If conversation tasks: report completion

## Step 5: Completion

After all waves pass review:

1. Run verification commands if known (from `.wave.yaml`, CLAUDE.md, or OpenSpec config)
2. Report:
   - What was built (per wave)
   - Review findings addressed
   - Verification results
3. Suggest next step:
   - If OpenSpec: suggest `/opsx:archive` or `/opsx:verify`
   - If branch work: suggest PR creation
   - If more work remains: suggest continuing

## Output format

```
## Wave Implementation: <source>

### Wave 1/3
Dispatching 2 implementation agents...
  Task 1: <description> — DONE
  Task 2: <description> — DONE

Review gate:
  Claude Opus: PASS
  Codex: PASS

### Wave 2/3
Dispatching 1 implementation agent...
  Task 3: <description> — DONE

Review gate:
  Claude Opus: PASS
  Codex: FAIL — [file:line] missing null check on ...
  Fix dispatched... fixed.
  Re-review: PASS

### Wave 3/3
...

## Complete
All 4 tasks implemented across 3 waves. 1 review fix applied.
```

## Rules

- Never skip a review gate. The whole point is catching issues before they compound.
- **ALL agents — implementation AND review — always dispatch with `run_in_background: true`.** The orchestrator never blocks on an agent; it dispatches, awaits the completion notification, then proceeds. This keeps the main session responsive throughout the run.
- Review agents always run in parallel (both in one message).
- Each wave's review sees only that wave's diff, not the full branch.
- If a review gate fails twice on the same issue, escalate to the user.
- Don't pause between waves to ask "should I continue?" Just go.
- Convention docs in every agent prompt. Agents that skip conventions produce code that fails review.
- Implementation agents on the same branch can share a worktree. Different branches need separate worktrees.
- **Run the integration/e2e gate, not just unit tests.** Unit-green hides two failure modes that only surface when the real app runs: (a) a *removed-API* call in an existing test that wasn't updated, and (b) tests still asserting the *old* behaviour a refactor replaced. A wave that changes behaviour MUST run the project's e2e/integration suite as a gate and rewrite any test that encodes the replaced behaviour — otherwise the suite passes while the observable thing is broken. (See "Verify the Observable, Not the Proxy".)
- **A refactor/removal wave isn't done when the new code compiles — it's done when the tests of the OLD behaviour are rewritten or deleted.** Grep the test tree for references to the removed API/model before declaring a wave green.
- **An implementation agent's "gates pass" is a CLAIM, not evidence. Re-run the gates yourself before the review gate.** An agent that cannot run part of the suite will filter it out and report green on the remainder — a check that cannot fail. Assert the **test count**, not just the exit status: pin the expected total (`1188 tests`) and treat a materially lower number as a failed gate, not a pass. FUS-192 wave 1 self-reported "1,020 passed"; the orchestrator's unfiltered run was 23 failed / 1161 passed / 1188 total, and every one of the 23 lived in the hosted tests the agent had excluded. Put the expected count in the implementation prompt so the agent can self-catch, and verify it anyway.
