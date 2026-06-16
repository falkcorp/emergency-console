#!/usr/bin/env bash
# emergency-console: launch a persistent emergency-console Claude session.
# Creates a tmux session running claude-loop so the session survives
# terminal disconnects and auto-resumes after being signaled.

set -euo pipefail

SESSION="emergency-console"
CONSOLE_DIR="$HOME/.claude/emergency-console"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Emergency console already running — attaching to $SESSION..."
  tmux attach-session -t "$SESSION"
  exit 0
fi

if ! command -v claude-loop >/dev/null 2>&1; then
  echo "ERROR: claude-loop not found." >&2
  echo "Run: bash $CONSOLE_DIR/install.sh" >&2
  exit 1
fi

if [ ! -f "$CONSOLE_DIR/restart_claudes.py" ]; then
  echo "ERROR: restart script not found at $CONSOLE_DIR/restart_claudes.py" >&2
  echo "Run: bash $CONSOLE_DIR/install.sh" >&2
  exit 1
fi

echo "Launching emergency console in tmux session $SESSION..."
tmux new-session -d -s "$SESSION" -x 220 -y 50
tmux send-keys -t "$SESSION" "cd $CONSOLE_DIR && claude-loop" Enter
echo "Attaching..."
tmux attach-session -t "$SESSION"
