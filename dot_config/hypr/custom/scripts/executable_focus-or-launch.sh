#!/usr/bin/env bash
# focus-or-launch: focus an existing window by class, or launch the app.
# Usage: focus-or-launch <class_regex> <command> [args...]
#
# Prefers windows on normal workspaces (id > 0) over scratchpad (id < 0).
# Falls back to any match if only scratchpad windows exist.
# Launches if no window found at all.

class="$1"
shift

# First preference: window on a normal workspace
normal=$(hyprctl clients -j | jq -r --arg c "$class" \
    '[.[] | select(.class | test($c; "i")) | select(.workspace.id > 0)] | first | .address // empty')

if [[ -n "$normal" ]]; then
    hyprctl dispatch focuswindow "address:$normal"
    exit 0
fi

# Fallback: any matching window (e.g. scratchpad)
any=$(hyprctl clients -j | jq -r --arg c "$class" \
    '[.[] | select(.class | test($c; "i"))] | first | .address // empty')

if [[ -n "$any" ]]; then
    hyprctl dispatch focuswindow "address:$any"
    exit 0
fi

# Nothing found — launch
hyprctl dispatch exec "$@"
