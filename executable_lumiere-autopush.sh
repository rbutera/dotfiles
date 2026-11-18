#!/usr/bin/env bash
# lumiere-autopush.sh  (bead workspace-xnv9g)
# Hourly (launchd, :37) push of ALREADY-COMMITTED local commits on develop in
# ~/dev/lumiere. Deliberately NOT like navi/expedition-autopush:
#   - lumiere is a shared multi-agent repo, so this NEVER runs git add / commit
#     and never touches the working tree or index of dirty files.
#   - only acts on branch `develop`; any other branch is a logged skip.
#   - behind origin: `pull --rebase` only when no tracked file is modified;
#     if tracked files are dirty it logs and skips (never --autostash).
#   - rebase conflict: `rebase --abort`, log, exit 1.
#   - pre-push hook (typecheck) failure: log, exit 1, and do not retry the same
#     HEAD sha (state file) so a broken tree does not burn a typecheck hourly.
#   - mkdir lock prevents overlapping runs (the hook can take minutes).
# Usage: lumiere-autopush.sh [--dry-run]   (dry run: all checks, push is `git push --dry-run`)
set -uo pipefail

REPO="${LUMIERE_AUTOPUSH_REPO:-$HOME/dev/lumiere}"
BRANCH_WANTED="develop"
STATE_DIR="$HOME/.local/state/lumiere-autopush"
LOCK="$STATE_DIR/lock"
FAILED_SHA_FILE="$STATE_DIR/hook-failed-sha"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] lumiere-autopush: $*"; }

# Same ssh bypass as the other autopush scripts (colima Include on external NVMe).
export GIT_SSH_COMMAND="ssh -F /dev/null -o IdentitiesOnly=yes -o IdentityFile=$HOME/.ssh/id_ed25519 -o UserKnownHostsFile=$HOME/.ssh/known_hosts"
# The pre-push hook runs npx/nx; launchd's PATH lacks node.
export PATH="$HOME/.vite-plus/bin:$HOME/.asdf/shims:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

mkdir -p "$STATE_DIR"
cd "$REPO" 2>/dev/null || { log "ERROR cannot cd into $REPO"; exit 1; }

if ! mkdir "$LOCK" 2>/dev/null; then
  # stale lock (> 2h) is cleared, otherwise another run is live
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +120 2>/dev/null)" ]; then
    rmdir "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || { log "SKIP lock busy"; exit 0; }
  else
    log "SKIP another run holds the lock"; exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "$BRANCH" != "$BRANCH_WANTED" ]; then
  log "SKIP checked-out branch is '$BRANCH', not $BRANCH_WANTED"; exit 0
fi

GITDIR="$(git rev-parse --git-dir)"
for marker in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD index.lock; do
  if [ -e "$GITDIR/$marker" ]; then log "SKIP git operation in progress ($marker)"; exit 0; fi
done

if ! git fetch -q origin "$BRANCH_WANTED" 2>&1; then
  log "ERROR fetch failed (network/ssh); nothing done"; exit 1
fi

read -r BEHIND AHEAD < <(git rev-list --left-right --count "origin/$BRANCH_WANTED...$BRANCH_WANTED")
log "develop is $AHEAD ahead, $BEHIND behind origin/develop (dry-run=$DRY)"

if [ "$AHEAD" -eq 0 ]; then
  log "nothing to push"; exit 0
fi

if [ "$BEHIND" -gt 0 ]; then
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    log "SKIP behind origin by $BEHIND but tracked files are modified; will not rebase over a dirty tree (no autostash). Retry next hour."
    exit 0
  fi
  if [ "$DRY" -eq 1 ]; then
    log "DRY would run: git pull --rebase origin develop ($BEHIND behind, tree clean)"
  elif ! git pull -q --rebase origin "$BRANCH_WANTED" 2>&1; then
    git rebase --abort >/dev/null 2>&1
    log "ERROR rebase conflict or failure; aborted cleanly, nothing pushed. Needs a human."
    exit 1
  else
    log "rebased onto origin/develop"
  fi
fi

HEAD_SHA="$(git rev-parse --short HEAD)"
if [ "$DRY" -eq 0 ] && [ -f "$FAILED_SHA_FILE" ] && [ "$(cat "$FAILED_SHA_FILE")" = "$HEAD_SHA" ]; then
  log "SKIP push of $HEAD_SHA already failed the pre-push hook; waiting for a new commit"
  exit 0
fi

if [ "$DRY" -eq 1 ]; then
  log "DRY would push these commits (git push is not run for real):"
  git log --oneline "origin/$BRANCH_WANTED..$BRANCH_WANTED" | head -20
  exit 0
fi

log "pushing $AHEAD commit(s), HEAD $HEAD_SHA (pre-push hook runs)"
if git push origin "$BRANCH_WANTED" 2>&1 | tail -25; [ "${PIPESTATUS[0]}" -eq 0 ]; then
  rm -f "$FAILED_SHA_FILE"
  log "pushed OK"
else
  echo "$HEAD_SHA" > "$FAILED_SHA_FILE"
  log "ERROR push failed (pre-push hook or remote reject) at $HEAD_SHA; not retrying this sha"
  exit 1
fi
