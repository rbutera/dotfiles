#!/usr/bin/env bash
# Toggle between dwindle and master layouts.
# Center-master orientation on A (workspaces 1-4) and C (workspaces 8-10)
# is handled by workspace rules in custom/rules.conf.

current=$(hyprctl getoption general:layout | awk '/str:/{print $2}')
if [ "$current" = "master" ]; then
    hyprctl keyword general:layout dwindle
else
    hyprctl keyword general:layout master
fi
