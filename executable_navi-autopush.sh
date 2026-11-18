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

ADD_ARGS=(-A -- .)
DEFER_COUNT=0
while IFS= read -r deferred; do
    [ -z "$deferred" ] && continue
    ADD_ARGS+=(":(exclude)$deferred")
    DEFER_COUNT=$((DEFER_COUNT + 1))
done <<< "$DEFER_LIST"

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

# Push with pull-rebase retry on non-fast-forward rejection.
# Fix B: the retry's rebase can be blocked by unstaged changes written by
# concurrent agent/session activity between the commit above and this retry
# (board.json, journal entries, memory files). Stash them first, restore after.
push_with_retry() {
    if git push origin "$BRANCH" 2>&1; then
        echo "$LOG_PREFIX Pushed successfully to $BRANCH. Commit: $COMMIT_MSG"
        return 0
    fi
    echo "$LOG_PREFIX Push failed (likely non-fast-forward or transient). Rebasing and retrying..."

    local stash_marker="autopush-retry-stash-$(date +%s)"
    local stash_needed=0
    if [ -n "$(git status --porcelain)" ]; then
        if git stash push --include-untracked -m "$stash_marker"; then
            stash_needed=1
            echo "$LOG_PREFIX Stashed in-flight changes ($stash_marker) before rebase retry."
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

    # Always try to restore the stash — never silently drop live data.
    if [ "$stash_needed" -eq 1 ]; then
        if git stash pop; then
            echo "$LOG_PREFIX Restored stashed changes after rebase retry."
        else
            echo "$LOG_PREFIX ERROR: stash pop conflicted. Stash '$stash_marker' is PRESERVED (git stash list) — manual resolution needed. Not dropping it."
        fi
    fi

    if [ "$rebase_ok" -ne 1 ]; then
        echo "$LOG_PREFIX ERROR: Push retry aborted after failed rebase. Manual intervention may be needed."
        return 1
    fi

    if git push origin "$BRANCH" 2>&1; then
        echo "$LOG_PREFIX Push succeeded after rebase. Commit: $COMMIT_MSG"
        return 0
    fi
    echo "$LOG_PREFIX ERROR: Push failed after rebase. Manual intervention may be needed."
    return 1
}

push_with_retry
