#!/usr/bin/env bash
# focus-or-launch: focus an existing window by class, or launch the app.
# Usage: focus-or-launch <class_regex> <command> [args...]
#
# class_regex: case-insensitive regex matched against window class
# command:     launched via hyprctl dispatch exec if no match found
#
# Examples:
#   focus-or-launch "brave-browser" brave
#   focus-or-launch "com.mitchellh.ghostty" ghostty

class="$1"
shift

exists=$(hyprctl clients -j | jq -r --arg c "$class" '[.[] | select(.class | test($c; "i"))] | length')

if [ "$exists" -gt 0 ]; then
    hyprctl dispatch focuswindow "class:$class"
else
    hyprctl dispatch exec "$@"
fi
