---
name: chezmoi-sync
description: Reconcile chezmoi source vs deployed dotfiles when they have drifted. Use when Rai says "sync dotfiles", "chezmoi drift", "dotfiles out of sync", "what's drifted", "chezmoi-sync", "reconcile dotfiles", or when an agent edited a deployed dotfile and the chezmoi source needs catching up. Pulls latest, checks git + 1Password session, finds drift, then walks each drifted file ONE AT A TIME through an update-source-vs-override-deployed decision, then commits and pushes only the files it changed. Calm, guided, never dumps the full diff at once.
allowed-tools: Bash, Read
---

# chezmoi-sync

Reconcile Rai's chezmoi **source** (`~/.local/share/chezmoi/`) with the
**deployed** dotfiles (`~/.zshrc`, `~/.config/*`, `~/.claude/*`, ...).

**Why this exists:** agents (and Rai) edit the DEPLOYED files and forget to
update the chezmoi SOURCE, so the two drift apart. The next `chezmoi apply`
then silently stomps the deployed edit, or the source rots. This skill catches
that drift and resolves it, **one file at a time**, with Rai in the loop on each.

**The whole point is calm.** Rai gets overwhelmed by a raw `chezmoi diff` of the
whole tree. NEVER dump the full diff. Take it one file at a time, lead with a
one-line summary of what changed, only expand the diff for the file in hand, and
ask one clear question per file.

## The two directions (memorize this)

For every drifted file there are exactly two resolutions:

| Decision | Meaning | Command |
|---|---|---|
| **Keep DEPLOYED** | the live file on disk is right; pull it back into source | `chezmoi add <file>` |
| **Keep SOURCE** | the source/template is right; overwrite the live file | `chezmoi apply --force <file>` |

Two hard rules, both validated live:

1. **`chezmoi apply` REQUIRES `--force` per-file here.** A bare
   `chezmoi apply <file>` prompts for a TTY confirmation and fails / hangs
   non-interactively. Always `chezmoi apply --force <file>`.
2. **NEVER `chezmoi add` a templated source** (`*.tmpl`, especially a secret
   one). `chezmoi add` overwrites the source with the *rendered literal* value —
   it destroys the template AND leaks the secret into source. For a templated
   file, "keep deployed" means **Rai hand-edits the template**; offer to open it,
   never auto-`add`.

Always scope every command to the **specific file**. Never a blanket
`chezmoi apply` / `chezmoi add`.

---

## Step 0 — Pull + git sync-check

```bash
git -C ~/.local/share/chezmoi pull --rebase --autostash
git -C ~/.local/share/chezmoi status -sb | head -3
```

Report ahead/behind vs origin in one line (e.g. "source repo: up to date with
origin/main" or "2 ahead, 0 behind — uncommitted source changes present").
If the pull hits a conflict, STOP and surface it — don't try to resolve git
conflicts inside this flow.

## Step 1 — 1Password session gate (timeout-guarded)

`chezmoi status` renders templates inline to compute target state, so any
`onepasswordRead` template makes the whole status walk call `op`. Without a
session that **hangs** — so guard every op touch with a timeout.

Cheap env pre-check, then an authoritative (timeout-guarded) probe:

```bash
# fast hint
env | grep -q '^OP_SESSION' && echo "env: session var present" || echo "env: no session var"
# authoritative — NEVER run a bare `op` command, it hangs on the auth prompt
timeout 5 op whoami >/dev/null 2>&1 && echo active || echo none
```

(Use `gtimeout` if `timeout` is absent — macOS coreutils.)

- **active** → continue to Step 2.
- **none** → tell Rai, verbatim guidance:
  > No 1Password session. Run `eval $(op signin --account personal)` in your
  > shell, then re-invoke `/chezmoi-sync`.

  Do NOT attempt to enumerate or apply secret files without it. (Non-secret
  files *can* be handled without op, but on this repo a global `chezmoi status`
  will hang on the first secret template, so the session is needed up front to
  get a complete drift picture. See Design notes.)

## Step 2 — Enumerate drift (use the helper)

Run the bundled detector — it's read-only and timeout-guarded:

```bash
bash ~/.claude/skills/chezmoi-sync/detect-drift.sh
```

(That path is the deployed location; the script lives at
`~/.local/share/chezmoi/dot_claude/skills/chezmoi-sync/detect-drift.sh` in source.)

It prints one line per drifted file:

```
/Users/rai/.zshrc | _M | template=no | secret=no
/Users/rai/.zshenv | _M | template=yes | secret=yes
```

Special outputs:
- **(empty, exit 0)** → no drift. Tell Rai "dotfiles are in sync" and stop.
- **`STATUS_BLOCKED | need-op-session` (exit 3)** → status timed out on a secret
  template with no op session. Go back to Step 1 and get Rai signed in.
- **`ERROR | ...` (exit 2)** → surface the error; don't guess.

Parse the lines into a worklist. Count them and tell Rai up front:
"N files drifted. Let's go through them one at a time." Then process in a stable
order (suggest: non-secret first — quickest wins — then templated/secret).

## Step 3 — Walk each file, ONE AT A TIME

For each file in the worklist, do exactly this and then **wait for Rai's call**
before moving on. Never batch. Never pre-render every diff.

### 3a. Lead with a one-line summary

State the file, its status code meaning, and its class:
> `~/.zshrc` — deployed file differs from source (non-secret). 

### 3b. Show the focused diff (scoped to this one file)

**Non-secret file** (`secret=no`) — safe without op:
```bash
chezmoi diff ~/.zshrc
```
Show it. If it's large, show a tight summary (hunk headers / first ~30 lines)
and offer "want the full diff?" rather than flooding the screen.

**Secret / templated file** (`secret=yes`) — needs the op session (have it from
Step 1). The rendered diff may expose secret values, so prefer to describe
*which fields* differ rather than dumping raw secret text:
```bash
chezmoi diff <file>     # only with an active op session
```
Summarize what differs; avoid echoing secret values into the transcript.

### 3c. Ask the one decision

> Keep **deployed** (pull the live file into source) or keep **source**
> (overwrite the live file)? Or **skip** this one?

### 3d. Execute the mapped command

- **Keep deployed** + `template=no` →
  ```bash
  chezmoi add <file>
  ```
- **Keep deployed** + `template=yes` (incl. all `secret=yes`) → **DO NOT add.**
  Warn:
  > `<file>` is a template — `chezmoi add` would overwrite the template and
  > inline the rendered value (leaking the secret). The deployed change needs to
  > go into the template by hand.

  Show the source path (`chezmoi source-path <file>`) and offer to open it for
  Rai to edit the template, then re-run sync.
- **Keep source** (either class) →
  ```bash
  chezmoi apply --force <file>
  ```
  (`--force` is required; plain apply prompts for a TTY.)
- **Skip** → leave it, note it as still-drifted in the final summary.

Confirm the result in one line, then move to the next file.

## Step 4 — Summary, then commit + push

After the worklist is done:

1. Re-run `bash ~/.claude/skills/chezmoi-sync/detect-drift.sh` to confirm what's
   left (should be empty, or only the files Rai skipped / deferred to manual
   template edits).
2. Summarize: resolved (kept-deployed / kept-source counts), skipped, and any
   templates flagged for manual edit.
3. **Commit + push the source changes this sync made.** This skill DOES commit
   and push — but **only the files it touched**, never a blanket `git add -A`.

   The repo often carries *unrelated* uncommitted source edits (e.g. someone was
   mid-change on `dot_config/impulse/jobs.json.tmpl`). Sweeping those into the
   sync commit is wrong. So stage **explicitly** the paths this run changed:
   - every source path written by a `chezmoi add <file>` (keep-deployed, plain),
   - every template you hand-edited (keep-deployed, templated),
   - any `logs/*.md` you updated for the change.

   Keep a running list of these source paths as you go through Step 3. Then:

   ```bash
   cd ~/.local/share/chezmoi
   # stage ONLY the paths this sync changed (one -- pathspec list, no `-A`)
   git add -- <path1> <path2> logs/<topic>.md ...
   # sanity-check you're committing only sync paths
   git status -sb
   git diff --cached --stat
   ```

   Write a commit message that summarizes the reconciliation per file
   (what was kept-deployed vs kept-source, and why), following the repo's commit
   conventions. Then commit and push:

   ```bash
   git commit -m "chezmoi-sync: <one-line summary>" -m "<per-file detail>"
   git push
   ```

   - If **nothing** was changed by the sync (everything was keep-source or
     skipped), there's nothing to stage — say so and skip the commit.
   - If staging would pick up unrelated changes, it won't: you named exact paths.
     Mention any leftover unrelated uncommitted files in the summary so Rai knows
     they're still pending (you did NOT commit them).
   - If `git push` fails (no upstream, auth, non-fast-forward), surface the error
     and the staged-but-unpushed commit; don't force-push.

## Rules

- One file at a time. Never dump a tree-wide diff. Calm over fast.
- Every `chezmoi diff` / `add` / `apply` is **scoped to a single file**.
- `chezmoi apply` is always `chezmoi apply --force <file>`.
- NEVER `chezmoi add` a `*.tmpl` source. Warn and route to manual template edit.
- NEVER run a bare `op` command — always `timeout`-guard it (it hangs on auth).
- This skill DOES commit + push at the end — but only the exact source paths it
  changed (staged by explicit pathspec, NEVER `git add -A`). It never signs into
  1Password; if a secret file needs an op session it can't get, defer it.
- Don't auto-resolve git conflicts in Step 0 — surface and stop. Don't force-push
  if the Step 4 push is rejected — surface the error and the unpushed commit.

---

## Design notes / open for Rai

These are choices I made that you may want to tune:

- **op session needed up front (not just for secret files).** In theory
  non-secret drift can be inspected with no 1Password session. In practice, a
  *global* `chezmoi status` on your repo HANGS the moment it hits the first
  `onepasswordRead` template (it renders templates to compute target hashes;
  validated live 2026-06-20 — it blocked on `dot_aider.conf.yml.tmpl`). So the
  helper times out and asks for a session before it can give a complete drift
  list. **Alternative if you want a true no-op fast path:** enumerate via
  `chezmoi managed` (no template eval) and run scoped `chezmoi status <file>`
  per non-secret file — slower (O(files)) but op-free. I didn't build that path
  by default; say the word and I'll add it as a `--no-op` mode to the helper.
- **How much diff to show.** Default: full diff for small non-secret files, a
  truncated summary (hunk headers / first ~30 lines) for big ones with an opt-in
  for the rest. Tune the threshold to taste.
- **Whitespace / trivial drift.** Right now every drifted file is its own
  prompt. If trivial whitespace-only or mode-only drift is noisy for you, I can
  add an auto-batch ("12 whitespace-only files — apply --force all? y/n") so the
  one-at-a-time flow is reserved for substantive diffs.
- **Default ordering.** Non-secret first (fast wins), then templated/secret.
  Could instead group by directory, or surface the scariest (secret) first.
- **Secret diff exposure.** For secret files I describe *which fields* differ
  rather than dumping rendered secret text into the transcript. If you'd rather
  see the raw rendered diff, that's a one-line change.
