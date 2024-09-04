#!/bin/bash

# Get the class of the focused window
FOCUSED_CLASS=$(hyprctl activewindow -j | jq -r '.class')

# Check if the focused window is one of the specified applications
if [[ "$FOCUSED_CLASS" =~ ^(Code|kitty|Alacritty|warp)$ ]]; then
  # If it is, send Ctrl+Shift+V
  wtype -M ctrl -M shift -P v -m shift -m ctrl
else
  # If it's not, send Ctrl+V
  wtype -M ctrl -P v -m ctrl
fi
