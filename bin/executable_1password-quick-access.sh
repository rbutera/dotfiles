#!/usr/bin/env bash

# Check if 1Password is running
running=$(hyprctl -j clients | jq -r '.[] | select(.class == "1Password") | .workspace.id')

if [[ $running != "" ]]; then
  # If running, switch to its workspace and focus it
  hyprctl dispatch workspace $running
  hyprctl dispatch focuswindow class:1Password
else
  # If not running, launch 1Password Quick Access
  1password --quick-access
fi

# Focus the 1Password window
sleep 0.5 # Give it a moment to launch
hyprctl dispatch focuswindow class:1Password
