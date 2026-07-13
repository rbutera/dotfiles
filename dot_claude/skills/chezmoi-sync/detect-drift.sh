#!/usr/bin/env bash
#
# detect-drift.sh — read-only chezmoi drift detector for the chezmoi-sync skill.
#
# WHAT IT DOES
#   Enumerates files that have drifted between the chezmoi SOURCE and the
#   DEPLOYED targets, and for each one emits a single structured, pipe-delimited
#   line the skill can parse:
#
#       <target-path> | <status-code> | template=<yes|no> | secret=<yes|no>
#
#   - target-path   absolute path of the deployed file (e.g. /Users/rai/.zshrc)
#   - status-code   the 2-char `chezmoi status` code, leading spaces shown as '_'
#                   (col1 = source changed since chezmoi last wrote the target;
#                    col2 = deployed file differs from target). Any non-space = drift.
#   - template      yes if the source is a *.tmpl (chezmoi renders it)
#   - secret        yes if the source is a *.tmpl AND references onepasswordRead
#                   / the onepassword template function (heuristic). These need an
#                   active 1Password session to render/diff, and must NEVER be
#                   `chezmoi add`-ed (it would overwrite the template + leak the
#                   secret literally into source).
#
# WHY THE op / timeout DANCE
#   `chezmoi status` renders templates inline to compute target hashes. On this
#   repo that means it calls `op` (1Password) for any onepasswordRead template,
#   and a bare `op` call BLOCKS on the auth prompt in a non-interactive shell.
#   So a global `chezmoi status` will HANG when no op session is active and any
#   secret template exists. We therefore:
#     1. run `chezmoi status` under a hard `timeout`;
#     2. if it times out (exit 124), emit a single sentinel line:
#            STATUS_BLOCKED | need-op-session
#        and exit 3 — the skill then asks Rai to sign in and re-runs us.
#   This script performs ZERO mutations and never signs in itself.
#
# READ-ONLY GUARANTEE
#   Only ever runs: chezmoi status / source-path, grep, timeout. No add, no apply,
#   no git writes, no op writes. Safe to run anywhere, any time.
#
# COMPAT: macOS bash 3.2; uses gtimeout if present else timeout; POSIX-careful.

set -u

# NOT $CHEZMOI — chezmoi exports CHEZMOI=1 into scripts it runs, so a shell that
# inherits that env would resolve the binary to "1".
CHEZMOI="${CHEZMOI_SYNC_BIN:-chezmoi}"
STATUS_TIMEOUT="${CHEZMOI_SYNC_STATUS_TIMEOUT:-20}"

# --- locate a timeout binary (gtimeout on macOS via coreutils, else timeout) ---
TIMEOUT_BIN=""
if command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
elif command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
fi

run_status() {
  # Prints chezmoi status output; returns the underlying exit code.
  # --no-tty keeps chezmoi from trying to drive an interactive prompt.
  if [ -n "$TIMEOUT_BIN" ]; then
    "$TIMEOUT_BIN" "$STATUS_TIMEOUT" "$CHEZMOI" status --no-tty 2>/dev/null
  else
    # No timeout available: still run, but it may hang on secret templates
    # without an op session. The skill's op-gate should run first anyway.
    "$CHEZMOI" status --no-tty 2>/dev/null
  fi
}

# --- sanity: chezmoi present ---
if ! command -v "$CHEZMOI" >/dev/null 2>&1; then
  echo "ERROR | chezmoi-not-found"
  exit 2
fi

STATUS_OUT="$(run_status)"
RC=$?

if [ "$RC" -eq 124 ]; then
  # timed out -> almost certainly a secret template needs an op session to render
  echo "STATUS_BLOCKED | need-op-session"
  exit 3
fi
if [ "$RC" -ne 0 ]; then
  echo "ERROR | chezmoi-status-exit-$RC"
  exit 2
fi

# No drift at all -> empty output, exit 0. The skill treats empty as "in sync".
if [ -z "$STATUS_OUT" ]; then
  exit 0
fi

# --- per-line classification ---
# chezmoi status format: two status columns, a space, then the path.
#   e.g. " M .zshrc"  or "MM .config/foo"  or "A  .newfile"
# We slice the first two columns as the code and the rest (from col 4) as path.
printf '%s\n' "$STATUS_OUT" | while IFS= read -r line; do
  [ -z "$line" ] && continue

  code="$(printf '%s' "$line" | cut -c1-2)"
  rel="$(printf '%s' "$line" | cut -c4-)"
  [ -z "$rel" ] && continue

  # Render spaces in the code as '_' so the field is never ambiguous/empty.
  code_disp="$(printf '%s' "$code" | tr ' ' '_')"

  # Resolve the absolute deployed (target) path. chezmoi status paths are
  # relative to the destination dir (home). Prefer chezmoi's own resolver so
  # we honor any custom destDir, falling back to ~/<rel>.
  target="$("$CHEZMOI" target-path "$rel" 2>/dev/null)"
  if [ -z "$target" ]; then
    target="$HOME/$rel"
  fi

  # Resolve the SOURCE path to classify template / secret.
  src="$("$CHEZMOI" source-path "$target" 2>/dev/null)"

  is_tmpl="no"
  is_secret="no"
  case "$src" in
    *.tmpl)
      is_tmpl="yes"
      if [ -f "$src" ] && grep -qE 'onepasswordRead|onepassword[ "(]' "$src" 2>/dev/null; then
        is_secret="yes"
      fi
      ;;
  esac

  printf '%s | %s | template=%s | secret=%s\n' "$target" "$code_disp" "$is_tmpl" "$is_secret"
done

exit 0
