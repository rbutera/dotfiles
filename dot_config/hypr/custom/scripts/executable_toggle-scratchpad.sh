#!/usr/bin/env bash
# toggle-scratchpad: auto-seed with a terminal if empty, then toggle visibility.
# The scratchpad is general-purpose — terminal is just the default seed.
# Send any window there with Shift+grave (movetoworkspacesilent special).

count=$(hyprctl clients -j | jq '[.[] | select(.workspace.name == "special")] | length')

if [ "$count" -eq 0 ]; then
    hyprctl dispatch exec "[workspace special silent] ghostty"
    sleep 0.1  # brief wait for window to register before toggling
fi

hyprctl dispatch togglespecialworkspace
