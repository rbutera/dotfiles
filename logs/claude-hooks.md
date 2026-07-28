# Claude Code hooks

Dated changelog for hook configuration in `dot_claude/`.

## 2026-07-28: shell-trap-check added as a second PreToolUse Bash hook

**Problem.** On the night of 2026-07-27/28 Navi hit five distinct instrument failures in one session: a truncated pretty-print produced a wrong count that reached Rai twice; a WebSearch summary produced a fabricated quote that reached him as fact and had to be retracted; a case-sensitive grep produced a false "that comment never landed"; a noise filter silently dropped a real member from an applicability sweep; and backticks inside a double-quoted shell string executed two bead ids as commands and deleted them from a memory file.

**Every one was already documented** in `~/expedition/Corrupt Instruments.md` or `~/expedition/Shell Quoting Traps On Nimbus.md`. Two were documented by Navi herself, hours earlier, the same night. That is the exact failure those documents describe, aimed at themselves: a correct thing living where nothing reads it at the moment of danger.

**Change.** `node /Users/rai/navi/bin/shell-trap-check.mjs` appended to the existing `Bash` matcher in `.hooks.PreToolUse`, alongside `rtk hook claude`. It reads the PreToolUse payload on stdin and warns on seven mechanically-detectable traps, each of which has cost something real: credential-leaking `${VAR:-x}` presence tests, `git add -A` in a shared tree, backticks inside double quotes, bare `>` under noclobber, establishing an absence from `head`/`tail` piped to grep, `bd list`/`bd ready` counted without `--limit 0`, and the Rule 76 destructive-git set.

⚠️ **It WARNS and never blocks, deliberately.** A blocking hook that false-positives gets switched off, and a switched-off guard is worse than none because it also carries the belief that something is watching. If a rule becomes noisy, delete the rule rather than the hook.

**Why the source and not the deployed file.** `.hooks.PreToolUse` is REBUILT wholesale by this modify script (line ~111), so an edit to `~/.claude/settings.json` alone would have been wiped on the next `chezmoi apply`. Caught by reading the script before trusting the edit. Verified after: `chezmoi diff ~/.claude/settings.json` shows only a trailing-newline difference, so source and live now agree.

**Tests.** `~/navi/tests/test_shell_trap_check.mjs`, 14 passing. The load-bearing one is the negative case: twelve ordinary everyday commands must produce zero warnings, because the false-positive rate is what decides whether this survives contact.
