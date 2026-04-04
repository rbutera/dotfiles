#!/usr/bin/env bash
# local-workspace: jump to, or move a window to, the Nth workspace on the current monitor.
# Usage: local-workspace <action> <n>
#   action: workspace | movetoworkspace
#   n:      1-based index relative to the current monitor's workspace range
#
# Monitor → workspace mapping (matches workspaces.conf):
#   A — DP-1:     workspaces 1-4  (base=0, max=4)
#   B — HDMI-A-2: workspaces 5-7  (base=4, max=3)
#   C — DP-2:     workspaces 8-10 (base=7, max=3)

action="$1"
n="$2"

monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

case "$monitor" in
    DP-1)     base=0; max=4 ;;
    HDMI-A-2) base=4; max=3 ;;
    DP-2)     base=7; max=3 ;;
    *)        base=0; max=4 ;;
esac

if [ "$n" -gt "$max" ]; then
    exit 0
fi

target=$((base + n))
hyprctl dispatch "$action" "$target"
