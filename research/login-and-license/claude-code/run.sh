#!/bin/bash
# usage: run.sh <container> <cmd> [wait]
c=$1; cmd=$2; w=${3:-8}
docker exec $c tmux kill-server 2>/dev/null; true
docker exec -e TERM=xterm-256color $c tmux new-session -d -x 110 -y 40 -s s "$cmd"
sleep $w
docker exec $c tmux capture-pane -p -t s
