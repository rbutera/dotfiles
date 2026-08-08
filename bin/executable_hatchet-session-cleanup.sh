#!/usr/bin/env bash
#
# hatchet-session-cleanup.sh -- prune expired Hatchet sessions.
#
# Hatchet-lite ships no garbage collection for its UserSession table, so it grows
# without bound (it once reached ~2.3M rows / 923MB and had to be pruned by hand).
# This IS the missing GC: a daily DELETE of the rows whose expiresAt is in the past.
#
# chezmoi deploys this to ~/bin on macOS AND Linux. It is a deliberate NO-OP where
# Docker or the Hatchet postgres container is absent, so it is harmless on any
# machine that does not (yet) run Hatchet.
#
# Scheduling is OS-specific and lives elsewhere:
#   macOS -> ~/Library/LaunchAgents/com.rai.hatchet-session-cleanup.plist
#   Linux -> ~/.config/systemd/user/hatchet-session-cleanup.{service,timer}
#
# No credentials are ever read or printed here: psql runs INSIDE the container and
# uses the container's own POSTGRES_USER / POSTGRES_DB env, which never leaves it.

set -euo pipefail

CONTAINER="e8n-hatchet-hatchet-postgres-1"
LOG_DIR="${HOME}/.logs"
LOG_FILE="${LOG_DIR}/hatchet-session-cleanup.log"

mkdir -p "${LOG_DIR}"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$1" >>"${LOG_FILE}"
}

# Safe no-op where Docker is unavailable (e.g. a machine that does not run Hatchet).
if ! command -v docker >/dev/null 2>&1; then
  log "docker not found, skipping"
  exit 0
fi

# Safe no-op where the Hatchet postgres container is not running.
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "${CONTAINER}"; then
  log "container ${CONTAINER} not running, skipping"
  exit 0
fi

# Prune expired sessions. psql runs inside the container against its own env, so no
# credentials are exposed. `|| true` keeps a transient psql error non-fatal under -e
# (a bad night logs and exits clean rather than wedging the scheduler).
result="$(docker exec "${CONTAINER}" sh -c \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DELETE FROM \"UserSession\" WHERE \"expiresAt\" < now();"' \
  2>&1 || true)"

# A successful DELETE prints the command tag "DELETE N" on its own line; extract N.
count="$(printf '%s\n' "${result}" | sed -n 's/^DELETE \([0-9][0-9]*\)$/\1/p' | tail -n1)"

if [ -n "${count}" ]; then
  log "deleted ${count} expired session(s)"
else
  # No clean row count -- record the raw output for diagnosis, still exit 0 so the
  # scheduler is never left in a failed state by one bad run.
  log "cleanup did not return a row count: ${result}"
fi

exit 0
