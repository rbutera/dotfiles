#!/usr/bin/env bash
# navi-autopush.sh
# Auto-commits and pushes ~/navi if the repo is dirty.
# Designed to be run via launchd at :47 past every hour.
# Mirrors expedition-autopush.sh — see also com.rai.navi-autopush.plist
#
# bd-coexistence: bd does NOT commit/push to git main (it syncs Dolt refs only).
# However, Navi or other agents can commit in-session, so push can fail with
# non-fast-forward. Strategy: pull --rebase before push; on rejection, retry once.
#
# FIXED 2026-07-07 (bead workspace-bkcos), three bugs found in one pass:
#   (A) git's ssh was reading colima's ssh_config Include on the external NVMe
#       ("Can't open user config file .../.colima/ssh_config: Interrupted system
#       call" -> "fatal: Could not read from remote repository"), intermittently,
#       whenever the external NVMe hiccuped. Fix: GIT_SSH_COMMAND below bypasses
#       ~/.ssh/config's colima Include entirely (-F /dev/null + explicit identity).
#   (B) the rebase-retry called `git pull --rebase` while the LIVE workspace had
#       unstaged in-flight changes (board.json, journal, memory files get written
#       by concurrent agent/session activity between the initial commit and the
#       retry), so the retry itself failed with "cannot pull with rebase: You have
#       unstaged changes." Fix: stash (incl. untracked) before the rebase attempt,
#       restore after, and never silently drop the stash on conflict.
#   (C) the script hardcoded `git push origin main` / `git pull --rebase origin
#       main` regardless of which branch was actually checked out. This repo has
#       lived on feat/proactive-send-guard for a while (see hot.md); local `main`
#       hadn't moved since 2026-06-21 and pushing it was a silent no-op — the
#       checkpoint commits landing on the real branch never reached origin via
#       this script at all. Fix: always operate on whatever branch is currently
#       checked out ($BRANCH), not a hardcoded name.

# FIXED 2026-11-27 (bead workspace-2le4a, follow-up to workspace-ipy4g). From 24 to 27 Nov
# every push failed with GitHub GH001 (two videos >100 MB swept in) and 60 checkpoints sat
# unpushed for ~50 h. Four faults, all fixed here:
#   (1) every push failure was treated as non-fast-forward (stash, rebase, retry). Now the
#       stderr is classified (large-file / auth / network / non-fast-forward /
#       pre-receive-declined / unknown) and ONLY non-fast-forward gets the rebase retry.
#   (2) `git stash push` with nothing to save exits 0, and the script then popped an OLD
#       unrelated stash, conflicting logs/*.jsonl; the next run's `git add -A` committed the
#       conflict markers. Now refs/stash is compared before and after, and the pop happens only
#       if a new stash was created. `git add -A` is refused while any path is unmerged.
#   (3) files over 95 MiB are held back from staging (and gitignored if untracked), never deleted.
#   (4) every run writes state/autopush-last-result.json {ok,cause,detail,at}; the
#       recap-health-monitor push-staleness guard puts the cause in its alert.

set -euo pipefail

# NAVI_AUTOPUSH_REPO exists so this script can be exercised end-to-end against a
# scratch repo. Unset (the launchd case) it is exactly $HOME/navi as before.
REPO="${NAVI_AUTOPUSH_REPO:-$HOME/navi}"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# --- Fix A: bypass colima's ssh_config Include (lives on the external NVMe,
# intermittently unreadable) by using a minimal, self-contained ssh invocation
# for all git-over-ssh operations in this script.
export GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o IdentityFile=$HOME/.ssh/id_ed25519 -o UserKnownHostsFile=$HOME/.ssh/known_hosts"

cd "$REPO" || { echo "$LOG_PREFIX ERROR: Could not cd into $REPO"; exit 1; }

# --- Fix C: always track the currently checked-out branch, never a hardcoded name.
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" = "HEAD" ]; then
    echo "$LOG_PREFIX ERROR: repo is in detached HEAD state, refusing to autopush (would push to the wrong ref)."
    exit 1
fi

# --- 2le4a: helper + last-result state file. NAVI_AUTOPUSH_LIB / NAVI_AUTOPUSH_STATE_DIR let a
# test run against a scratch repo. Both default to the real ~/navi locations.
AUTOPUSH_LIB="${NAVI_AUTOPUSH_LIB:-$HOME/navi/bin/autopush-lib.mjs}"
RESULT_FILE="${NAVI_AUTOPUSH_STATE_DIR:-$REPO/state}/autopush-last-result.json"

resolve_node() {
    local candidate
    for candidate in node "$HOME/.asdf/shims/node" /opt/homebrew/bin/node /usr/local/bin/node; do
        if command -v "$candidate" >/dev/null 2>&1 && "$candidate" --version >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# record_result <ok 0|1> <cause> <detail> -- never fatal: the backup is the vital circuit.
record_result() {
    local nb
    nb="$(resolve_node)" || { echo "$LOG_PREFIX WARN: cannot record result, no working node."; return 0; }
    [ -f "$AUTOPUSH_LIB" ] || { echo "$LOG_PREFIX WARN: cannot record result, $AUTOPUSH_LIB missing."; return 0; }
    "$nb" "$AUTOPUSH_LIB" result --file "$RESULT_FILE" --ok "$1" --cause "$2" --detail "$3" \
        --branch "$BRANCH" --commit "${COMMIT_MSG:-}" || echo "$LOG_PREFIX WARN: could not write $RESULT_FILE."
    return 0
}

# classify_push_failure <stderr-text> -> sets PUSH_CAUSE and PUSH_DETAIL
classify_push_failure() {
    PUSH_CAUSE="unknown"
    PUSH_DETAIL="$(printf '%s' "$1" | tail -n 1)"
    local nb out
    if nb="$(resolve_node)" && [ -f "$AUTOPUSH_LIB" ] && out="$(printf '%s' "$1" | "$nb" "$AUTOPUSH_LIB" classify)"; then
        PUSH_CAUSE="${out%%$'\t'*}"
        PUSH_DETAIL="${out#*$'\t'}"
    elif printf '%s' "$1" | grep -qE 'non-fast-forward|\(fetch first\)|Updates were rejected because'; then
        # helper unavailable: recognise only the one class that is safe to retry
        PUSH_CAUSE="non-fast-forward"
    fi
}

COMMIT_MSG=""

# Check if repo is dirty (tracked changes, untracked files, or staged changes)
if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
    echo "$LOG_PREFIX Repo is clean, nothing to do. (branch: $BRANCH)"
    exit 0
fi

echo "$LOG_PREFIX Dirty repo detected on branch $BRANCH, committing..."

# Sync remote state before committing to avoid non-fast-forward push failures
git fetch origin "$BRANCH" --quiet || echo "$LOG_PREFIX WARN: fetch failed, continuing anyway"

# --- ur5p4 (2026-07-29): ask the guard which paths are an agent's LIVE in-flight
# work before staging. On 2026-07-28 this job fired twice in one hour while
# subagents were mid-write and pushed unverified source to origin as Rai --
# 23:47 077605a3 swept bin/clean-worktree-check.mjs and a brand-new 157-line test
# file, i.e. the tool whose job is to verify that pushes are safe.
#
# The guard NEVER modifies the repo. It only prints pathspecs to hold back this
# run, and a hold is a DELAY, not an exclusion: the file is committed by the next
# run once its mtime settles. Its stderr flows to this script's stderr and so to
# ~/.logs/navi-autopush.log -- no second surface.
#
# IT FAILS OPEN, DELIBERATELY. Any error prints nothing to stdout, so the
# exclusion list is empty and staging behaves exactly as it did before the guard
# existed. The hourly backup is the vital circuit; the guard is not. A guard that
# silently stopped the backup would be worse than the bug it fixes.
GUARD="$REPO/bin/autopush-guard.mjs"

# launchd does NOT get the interactive shell's PATH. node here lives at
# ~/.asdf/shims/node, which is on none of the plist's PATH entries -- so the
# 00:47 run on 2026-07-29 skipped the guard entirely and logged
# "autopush-guard unavailable" while the file was sitting right there.
# Resolve node explicitly, and prove each candidate by RUNNING it rather than by
# testing that the path exists: an asdf shim can exist and still fail to resolve
# a version. The shim is preferred over the versioned install path because the
# latter silently rots the next time node is upgraded.
NODE_BIN=""
for candidate in node "$HOME/.asdf/shims/node" /opt/homebrew/bin/node /usr/local/bin/node; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" --version >/dev/null 2>&1; then
        NODE_BIN="$candidate"
        break
    fi
done

DEFER_LIST=""
if [ -n "$NODE_BIN" ] && [ -f "$GUARD" ]; then
    DEFER_LIST="$($NODE_BIN "$GUARD" --repo "$REPO" || true)"
else
    if [ -z "$NODE_BIN" ]; then
        echo "$LOG_PREFIX WARN: autopush-guard SKIPPED -- no working node found on PATH=$PATH. Staging everything, as before."
    else
        echo "$LOG_PREFIX WARN: autopush-guard SKIPPED -- $GUARD missing. Staging everything, as before."
    fi
fi

# --- 2le4a (2): never stage while any path is unmerged. On 26 Nov a failed stash pop left UU
# paths and the next `git add -A` committed the conflict markers into logs/.
UNMERGED="$(git diff --name-only --diff-filter=U || true)"
if [ -n "$UNMERGED" ]; then
    UNMERGED_COUNT="$(printf '%s\n' "$UNMERGED" | grep -c . || true)"
    echo "$LOG_PREFIX ERROR: REFUSING to run 'git add -A': $UNMERGED_COUNT unmerged path(s) (conflict markers would be committed): $(printf '%s' "$UNMERGED" | tr '\n' ' ')"
    echo "$LOG_PREFIX ERROR: resolve them by hand (git status), then the next run proceeds. Nothing staged, nothing pushed."
    record_result 0 "unmerged-paths" "$UNMERGED_COUNT unmerged path(s): $(printf '%s' "$UNMERGED" | tr '\n' ' ' | cut -c1-200)"
    exit 1
fi

ADD_ARGS=(-A -- .)
DEFER_COUNT=0
while IFS= read -r deferred; do
    [ -z "$deferred" ] && continue
    ADD_ARGS+=(":(exclude)$deferred")
    DEFER_COUNT=$((DEFER_COUNT + 1))
done <<< "$DEFER_LIST"

# --- 2le4a (3): size gate. Hold back anything over 95 MiB (GitHub rejects >100 MiB with GH001).
# Untracked ones are appended to .gitignore; nothing is ever deleted. Fails open (a gate that
# stopped the backup would be worse than the bug), but says so loudly.
OVERSIZE_COUNT=0
if [ -n "$NODE_BIN" ] && [ -f "$AUTOPUSH_LIB" ]; then
    if OVERSIZE_LIST="$($NODE_BIN "$AUTOPUSH_LIB" hold-back --repo "$REPO" --limit-mb 95)"; then
        while IFS=$'\t' read -r kind big; do
            [ -z "$big" ] && continue
            OVERSIZE_COUNT=$((OVERSIZE_COUNT + 1))
            if [ "$kind" = "exclude" ]; then
                # tracked + modified: cannot be gitignored, so keep it out of this commit
                ADD_ARGS+=(":(exclude,literal)$big")
                echo "$LOG_PREFIX WARN: size gate held back tracked file $big (over 95 MiB). Left on disk, not staged."
            else
                # untracked: now in .gitignore, which git add honours (naming it as an exclude would error)
                echo "$LOG_PREFIX WARN: size gate held back $big (over 95 MiB), appended to .gitignore. Left on disk, not staged."
            fi
        done <<< "$OVERSIZE_LIST"
    else
        echo "$LOG_PREFIX WARN: size gate FAILED to run -- staging without it."
    fi
else
    echo "$LOG_PREFIX WARN: size gate SKIPPED -- no node or $AUTOPUSH_LIB missing."
fi

git add "${ADD_ARGS[@]}"

COMMIT_MSG="auto: checkpoint $(date '+%Y-%m-%d %H:%M:%S')"

if git diff --cached --quiet; then
    # Nothing to commit. Two quite different causes, and the log must not blame
    # the wrong one -- observed live on the 00:49 run, where the repo read dirty
    # only because a submodule had modified CONTENT, which `git add -A` in the
    # parent does not stage.
    if [ "$DEFER_COUNT" -gt 0 ]; then
        echo "$LOG_PREFIX Nothing staged: the guard held all $DEFER_COUNT dirty path(s). Work is still on disk, next run will take it."
    else
        echo "$LOG_PREFIX Nothing staged and the guard held nothing. The repo reads dirty for something 'git add -A' does not stage (e.g. modified content inside a submodule). Not an error."
    fi
    # Fall through to the push anyway, so any earlier unpushed commit still lands.
    COMMIT_MSG="(no new commit this run)"
else
    # Label the commit so a source-carrying checkpoint is findable afterwards.
    # 8.2% of the last 400 checkpoints touched bin/ tests/ skills/ plugins/ under a
    # message that described nothing.
    # Written as an if-block for legibility. I first wrote it as
    # `[ -n "$X" ] && LABEL=...` and suspected that would abort under `set -e`;
    # I tested it and it does NOT -- bash exempts a non-final command in an
    # AND-list. Recording that here so nobody "fixes" this back and forth on a
    # hazard that was never real.
    LABEL=""
    if [ -n "$NODE_BIN" ]; then
        LABEL="$($NODE_BIN "$GUARD" --repo "$REPO" --label 2>/dev/null || true)"
    fi
    if [ -n "$LABEL" ]; then
        COMMIT_MSG="$COMMIT_MSG [$LABEL]"
    fi
    if [ "$DEFER_COUNT" -gt 0 ]; then
        COMMIT_MSG="$COMMIT_MSG (held $DEFER_COUNT in-flight)"
    fi
    git commit -m "$COMMIT_MSG"
fi

# Push with pull-rebase retry ONLY for non-fast-forward.
# Fix B: the retry's rebase can be blocked by unstaged changes written by concurrent
# agent/session activity between the commit above and this retry. Stash first, restore after.
# 2le4a: a failure of any other class (large file, auth, network, other pre-receive decline,
# unknown) is logged with its cause and returned; rebasing cannot fix it.
push_with_retry() {
    local out
    if out="$(git push origin "$BRANCH" 2>&1)"; then
        printf '%s\n' "$out"
        echo "$LOG_PREFIX Pushed successfully to $BRANCH. Commit: $COMMIT_MSG"
        record_result 1 "pushed" ""
        return 0
    fi
    printf '%s\n' "$out"
    classify_push_failure "$out"
    echo "$LOG_PREFIX ERROR: push FAILED, cause=$PUSH_CAUSE: $PUSH_DETAIL"
    if [ "$PUSH_CAUSE" != "non-fast-forward" ]; then
        echo "$LOG_PREFIX ERROR: cause '$PUSH_CAUSE' cannot be fixed by pull --rebase, NOT retrying. Needs a human or a transient to clear."
        record_result 0 "$PUSH_CAUSE" "$PUSH_DETAIL"
        return 1
    fi
    echo "$LOG_PREFIX Non-fast-forward. Rebasing and retrying..."

    local stash_marker="autopush-retry-stash-$(date +%s)"
    local stash_needed=0
    local before_stash after_stash
    if [ -n "$(git status --porcelain)" ]; then
        # 2le4a (2): `git stash push` exits 0 with "No local changes to save" (e.g. only submodule
        # content is dirty), and popping then would restore an OLD unrelated stash. Pop only a
        # stash this run actually created.
        before_stash="$(git rev-parse -q --verify refs/stash || true)"
        if git stash push --include-untracked -m "$stash_marker"; then
            after_stash="$(git rev-parse -q --verify refs/stash || true)"
            if [ -n "$after_stash" ] && [ "$after_stash" != "$before_stash" ]; then
                stash_needed=1
                echo "$LOG_PREFIX Stashed in-flight changes ($stash_marker) before rebase retry."
            else
                echo "$LOG_PREFIX No stash was created (refs/stash unchanged); will NOT pop."
            fi
        else
            echo "$LOG_PREFIX WARN: stash failed, attempting rebase anyway."
        fi
    fi

    local rebase_ok=0
    if git pull --rebase origin "$BRANCH"; then
        rebase_ok=1
    else
        echo "$LOG_PREFIX ERROR: rebase failed. Aborting rebase to avoid a stuck repo."
        git rebase --abort 2>/dev/null || true
    fi

    # Restore only OUR stash -- never silently drop live data, never pop someone else's.
    if [ "$stash_needed" -eq 1 ]; then
        if [ "$(git rev-parse -q --verify refs/stash || true)" != "$after_stash" ]; then
            echo "$LOG_PREFIX ERROR: refs/stash moved since this run created $stash_marker; NOT popping. Stash preserved (git stash list)."
        elif git stash pop; then
            echo "$LOG_PREFIX Restored stashed changes after rebase retry."
        else
            echo "$LOG_PREFIX ERROR: stash pop conflicted. Stash '$stash_marker' is PRESERVED (git stash list) -- manual resolution needed. Not dropping it."
        fi
    fi

    if [ "$rebase_ok" -ne 1 ]; then
        echo "$LOG_PREFIX ERROR: Push retry aborted after failed rebase. Manual intervention may be needed."
        record_result 0 "rebase-failed" "pull --rebase failed after non-fast-forward"
        return 1
    fi

    if out="$(git push origin "$BRANCH" 2>&1)"; then
        printf '%s\n' "$out"
        echo "$LOG_PREFIX Push succeeded after rebase. Commit: $COMMIT_MSG"
        record_result 1 "pushed" "after rebase"
        return 0
    fi
    printf '%s\n' "$out"
    classify_push_failure "$out"
    echo "$LOG_PREFIX ERROR: Push failed after rebase, cause=$PUSH_CAUSE: $PUSH_DETAIL. Manual intervention may be needed."
    record_result 0 "$PUSH_CAUSE" "$PUSH_DETAIL (after rebase)"
    return 1
}

push_with_retry
