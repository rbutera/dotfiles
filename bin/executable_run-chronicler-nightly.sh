#!/usr/bin/env bash
set -euo pipefail

export HOME="/home/rai"
export PATH="/home/rai/bin:/home/rai/.local/bin:/home/rai/.local/share/pnpm:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/bin:/home/rai/.asdf/shims"

# Load asdf into the shell so pnpm/node resolve cleanly
. /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh

cd /home/rai/dev/lumiere

echo "HOME=$HOME"
echo "PATH=$PATH"
command -v asdf || true
command -v pnpm || true
command -v node || true
command -v discord-export || true

# Export vars from .env-style files
set -a
[ -f /home/rai/dev/lumiere/.env ] && . /home/rai/dev/lumiere/.env
[ -f /home/rai/dev/lumiere/apps/chronicler/.env ] && . /home/rai/dev/lumiere/apps/chronicler/.env
set +a

# Refresh export first
discord-export 1473760382387621950

# Run Chronicler using ~/.chronicler.json
# Only process yesterday and today (yesterday hits cache, today is the real work)
YESTERDAY=$(date -d 'yesterday' +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
pnpm nx run chronicler:dev -- --from "$YESTERDAY" --to "$TODAY"
