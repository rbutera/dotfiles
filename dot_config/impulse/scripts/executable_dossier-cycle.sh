#!/bin/bash
# dossier-cycle.sh — Refresh the oldest Chronicler topic dossier
# Called by Impulse every 4 hours. Self-balancing: the most stale
# dossier always gets attention next.

set -euo pipefail

TOPICS_DIR="/Users/rai/dev/lumiere/apps/chronicler/output/topics"
REPO_ROOT="/Users/rai/dev/lumiere"

# Find the oldest topic dossier by modification time
OLDEST_FILE=$(find "$TOPICS_DIR" -name "*.md" -maxdepth 2 | while read f; do
  stat -f "%m %N" "$f"
done | sort -n | head -1 | cut -d' ' -f2-)

if [ -z "$OLDEST_FILE" ]; then
  echo "No topic dossiers found in $TOPICS_DIR"
  exit 0
fi

TOPIC=$(basename "$(dirname "$OLDEST_FILE")")
echo "Refreshing oldest dossier: $TOPIC ($(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$OLDEST_FILE"))"

cd "$REPO_ROOT"
pnpm nx run chronicler:dev -- topic-dossier "$TOPIC" --agent navi

echo "TICK_COMPLETE: refreshed $TOPIC"
