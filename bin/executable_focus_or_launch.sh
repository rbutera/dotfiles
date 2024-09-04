#!/bin/sh

execCommand="$1"
className="$2"
workspaceOnStart="$3"

running=$(hyprctl -j clients | jq -r ".[] | select(.class == \"${className}\") | .workspace.id")

if [ -n "$running" ]; then
  hyprctl dispatch workspace "$running"
else
  if [ -n "$workspaceOnStart" ]; then
    hyprctl dispatch workspace "$workspaceOnStart"
  fi
  $execCommand &
fi
