#!/usr/bin/env bash
# expedition-autopush.sh
# Auto-commits (if dirty) AND pushes ~/dev/expedition if it has commits
# ahead of its upstream. Designed to be run via launchd at :17 past every hour.
#
# FIXED 2026-07-07 (bead workspace-bkcos), two bugs found:
#   (A) git's ssh was reading colima's ssh_config Include on the external NVMe
#       ("Can't open user config file .../.colima/ssh_config: Interrupted system
#       call" -> "fatal: Could not read from remote repository"), intermittently,
#       whenever the external NVMe hiccuped. Fix: GIT_SSH_COMMAND below bypasses
#       ~/.ssh/config's colima Include entirely (-F /dev/null + explicit identity).
#   (B) the script only ever pushed when the tree was DIRTY. It never checked for
#       commits already made locally but not yet pushed (e.g. commits made
#       directly by Rai/agents outside this script). Once a commit landed and the
#       tree went clean again, the script printed "Repo is clean, nothing to do"
#       every hour and silently stopped backing up — caught 2026-07-07 with the
#       repo 65 commits / 5 days ahead of origin, tree clean throughout. Fix: also
#       push whenever there are commits ahead of the upstream, independent of the
#       dirty check.

set -euo pipefail

REPO="$HOME/dev/expedition"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# --- Fix A: bypass colima's ssh_config Include (lives on the external NVMe,
# intermittently unreadable) by using a minimal, self-contained ssh invocation
# for all git-over-ssh operations in this script.
export GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o IdentityFile=$HOME/.ssh/id_ed25519 -o UserKnownHostsFile=$HOME/.ssh/known_hosts"

cd "$REPO" || { echo "$LOG_PREFIX ERROR: Could not cd into $REPO"; exit 1; }

DIRTY=0
if ! (git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]); then
    DIRTY=1
fi

if [ "$DIRTY" -eq 1 ]; then
    echo "$LOG_PREFIX Dirty repo detected, committing..."
    git add -A
    COMMIT_MSG="auto: checkpoint $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
else
    echo "$LOG_PREFIX Repo is clean, no new commit needed."
fi

# --- Fix B: push whenever there are commits ahead of the upstream, whether or
# not this run created a new one. Requires an upstream to be configured; if not,
# skip the ahead-check (nothing sane to compare against) but still surface it.
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
UPSTREAM="$(git for-each-ref --format='%(upstream:short)' "refs/heads/$BRANCH" 2>/dev/null || true)"

if [ -z "$UPSTREAM" ]; then
    echo "$LOG_PREFIX WARN: branch $BRANCH has no upstream configured, cannot check ahead-count. Skipping push."
    exit 0
fi

AHEAD_COUNT="$(git rev-list "$UPSTREAM..$BRANCH" 2>/dev/null | wc -l | tr -d ' ')"

if [ "$AHEAD_COUNT" -eq 0 ]; then
    echo "$LOG_PREFIX Nothing ahead of $UPSTREAM, nothing to push."
    exit 0
fi

echo "$LOG_PREFIX $AHEAD_COUNT commit(s) ahead of $UPSTREAM, pushing..."
git push
echo "$LOG_PREFIX Pushed successfully."
