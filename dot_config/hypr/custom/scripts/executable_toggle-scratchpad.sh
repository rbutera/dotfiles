#!/usr/bin/env bash
# toggle-scratchpad: auto-seed with a terminal if empty, then toggle visibility.
# The scratchpad is general-purpose — terminal is just the default seed.
# Send any window there with Shift+grave (movetoworkspacesilent special).

# Prevent parallel invocations from racing (rapid key presses)
LOCKFILE="/tmp/toggle-scratchpad.lock"
exec 9>"$LOCKFILE"
flock -n 9 || exit 0

# Special workspaces have negative IDs in Hyprland
count=$(hyprctl clients -j | jq '[.[] | select(.workspace.id < 0)] | length')

if [ "$count" -eq 0 ]; then
    hyprctl dispatch exec "[workspace special silent] ghostty"
    # Wait for ghostty to fully land in the special workspace before toggling.
    # Poll until registered, then add a settling pause — toggling too early
    # causes the window to escape to the current workspace.
    for i in $(seq 1 40); do
        sleep 0.05
        new_count=$(hyprctl clients -j | jq '[.[] | select(.workspace.id < 0)] | length')
        [ "$new_count" -gt 0 ] && break
    done
    sleep 0.2
fi

hyprctl dispatch togglespecialworkspace
