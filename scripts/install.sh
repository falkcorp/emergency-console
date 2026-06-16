#!/usr/bin/env bash
# install.sh: set up the emergency-console plugin dependencies.
# Run this once after installing the plugin:
#   claude plugin install falkcorp/emergency-console
#   bash "$(claude plugin path falkcorp/emergency-console)/scripts/install.sh"
#
# Or run directly from the repo root:
#   bash scripts/install.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONSOLE_DIR="$HOME/.claude/emergency-console"
BIN_DIR="$HOME/.local/bin"

echo "=== Emergency Console Install ==="
echo "Plugin dir: $PLUGIN_DIR"
echo "Console dir: $CONSOLE_DIR"

mkdir -p "$CONSOLE_DIR" "$BIN_DIR"

# 1. Install claude-loop
if [ ! -f "$BIN_DIR/claude-loop" ]; then
  echo "Installing claude-loop -> $BIN_DIR/claude-loop"
  install -m 755 "$PLUGIN_DIR/assets/claude-loop.sh" "$BIN_DIR/claude-loop"
else
  echo "claude-loop already installed at $BIN_DIR/claude-loop"
fi

# 2. Install restart script
echo "Copying restart_claudes.py -> $CONSOLE_DIR/"
cp "$PLUGIN_DIR/scripts/restart_claudes.py" "$CONSOLE_DIR/restart_claudes.py"

# 3. Install session CLAUDE.md (only if not already customized)
if [ ! -f "$CONSOLE_DIR/CLAUDE.md" ]; then
  echo "Copying session config -> $CONSOLE_DIR/CLAUDE.md"
  cp "$PLUGIN_DIR/assets/session.md" "$CONSOLE_DIR/CLAUDE.md"
else
  echo "Skipping CLAUDE.md (already exists — won't overwrite customizations)"
fi

# 4. Install launcher
echo "Installing launcher -> $BIN_DIR/emergency-console"
install -m 755 "$PLUGIN_DIR/assets/launcher.sh" "$BIN_DIR/emergency-console"

echo ""
echo "=== Done ==="
echo "Add $BIN_DIR to PATH if not already there:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo ""
echo "Launch the emergency console:"
echo "  emergency-console"
