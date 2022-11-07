#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Dismiss macOS Notifications
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName MacOS

# Documentation:
# @raycast.description Dismisses all notifications in notification center
# @raycast.author rbutera
# @raycast.authorURL https://github.com/rbutera

osascript -e 'tell application "Keyboard Maestro Engine" to do script "Dismiss macOS notifications"'
