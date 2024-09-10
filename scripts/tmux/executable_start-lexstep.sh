#!/bin/bash

set -x

SESSION="lexstep"
WINDOW="servers"

echo "Checking if session exists..."
tmux has-session -t $SESSION 2>/dev/null || tmux new-session -d -s $SESSION

echo "Checking if window exists..."
tmux list-windows -t $SESSION | grep -q $WINDOW || tmux new-window -t $SESSION -n $WINDOW

echo "Switching to window..."
tmux select-window -t $SESSION:$WINDOW

echo "Attempting to kill extra panes..."
tmux kill-pane -a -t $SESSION:$WINDOW.0 || echo "Failed to kill panes, continuing..."

echo "Clearing first pane..."
tmux send-keys -t $SESSION:$WINDOW.0 C-l Enter

echo "Starting angularjs-client..."
tmux send-keys -t $SESSION:$WINDOW.0 "cd ~/dev/angularjs-client && yarn start" C-m
sleep 1

echo "Splitting pane horizontally for lexstep-nest..."
tmux split-window -h -t $SESSION:$WINDOW
sleep 1

echo "Starting lexstep-nest..."
tmux send-keys -t $SESSION:$WINDOW.1 "cd ~/dev/lexstep-nest && yarn start:dev" C-m
sleep 1

echo "Splitting pane vertically for lexstep-agent..."
tmux split-window -v -t $SESSION:$WINDOW.1
sleep 1

echo "Starting lexstep-agent..."
tmux send-keys -t $SESSION:$WINDOW.2 "cd ~/dev/lexstep-agent && pnpm dev" C-m

echo "Script completed"
