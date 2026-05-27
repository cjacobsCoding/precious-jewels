#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(pwd)"
GODOT_CMD="${GODOT_CMD:-}"

if [ -z "$GODOT_CMD" ]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_CMD=godot
  elif command -v godot4 >/dev/null 2>&1; then
    GODOT_CMD=godot4
  elif command -v godot5 >/dev/null 2>&1; then
    GODOT_CMD=godot5
  else
    echo "Godot CLI not found. Install Godot or set GODOT_CMD to the executable path."
    exit 1
  fi
fi

echo "Using Godot executable: $GODOT_CMD"
"$GODOT_CMD" --headless --path "$ROOT" --script "$ROOT/tests/test_runner.gd"
