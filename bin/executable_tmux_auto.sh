#!/bin/sh

tmux_auto() {
  if tmux ls >/dev/null 2>&1; then
    tmux attach-session -t 0
  else
    tmux new-session
  fi
}

tmux_auto
