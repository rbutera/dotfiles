#!/bin/bash

# Name of the tmux session
SESSION="lexstep"

# Name of the window
WINDOW="servers"

# Duplicate protection: check if ports are in use
ports_to_check=(3001 9000 3000)
for port in "${ports_to_check[@]}"; do
  if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
    echo "Port $port is already in use. Aborting as Lexstep servers might be running."
    tmux attach-session -t $SESSION
    exit 1
  fi
done

# Rest of the script remains the same...
# (Include all the tmux commands from the previous script here)

# Check if the session exists
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
  # Session doesn't exist, create it
  tmux new-session -d -s $SESSION
fi

# Check if the window exists
tmux list-windows -t $SESSION | grep $WINDOW

if [ $? != 0 ]; then
  # Window doesn't exist, create it
  tmux new-window -t $SESSION -n $WINDOW
fi

# Switch to the window
tmux select-window -t $SESSION:$WINDOW

# Clear the window of any existing panes
tmux kill-pane -a -t $SESSION:$WINDOW

# Start angularjs-client
tmux send-keys -t $SESSION:$WINDOW "cd ~/dev/angularjs-client && yarn start" C-m

# Split pane horizontally and start lexstep-nest
tmux split-window -h -t $SESSION:$WINDOW
tmux send-keys -t $SESSION:$WINDOW.1 "cd ~/dev/lexstep-nest && yarn start:dev" C-m

# Split pane vertically and start lexstep-agent
tmux split-window -v -t $SESSION:$WINDOW.1
tmux send-keys -t $SESSION:$WINDOW.2 "cd ~/dev/lexstep-agent && pnpm dev" C-m

# Attach to the session
tmux attach-session -t $SESSION:$WINDOW
