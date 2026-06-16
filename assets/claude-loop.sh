#!/usr/bin/env bash
# claude-loop: run `claude` in a restart-on-request loop.
#
# After `claude` exits, the wrapper checks for a sentinel file at
#   ${TMPDIR:-/tmp}/claude-loop-restart-<child-pid>
# If present, it relaunches with --continue so the same session resumes.
# Otherwise it exits normally (user quit).
#
# The companion skill `restart-other-claudes` creates that sentinel right
# before sending SIGHUP, so HUPing a wrapped claude cycles it in place.

set -u
SENTINEL_DIR="${TMPDIR:-/tmp}"
ARGS=("$@")

while :; do
  claude "${ARGS[@]}" &
  CHILD=$!
  SENTINEL="$SENTINEL_DIR/claude-loop-restart-$CHILD"
  # Forward Ctrl+C etc. to the child instead of killing the loop.
  trap 'kill -INT $CHILD 2>/dev/null' INT
  wait "$CHILD"
  STATUS=$?
  trap - INT

  if [[ -f "$SENTINEL" ]]; then
    rm -f "$SENTINEL"
    ARGS=(--continue)
    continue
  fi
  exit "$STATUS"
done
