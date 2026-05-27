#!/usr/bin/env bash
set -euo pipefail

# Serves the exported HTML5 build on port 8000 (or $PORT).
BUILD_DIR="$(pwd)/builds/html5"
PORT="${PORT:-8000}"

if [ ! -d "$BUILD_DIR" ]; then
  echo "Build directory not found: $BUILD_DIR"
  echo "Run ./scripts/export_html.sh first to produce an HTML5 export."
  exit 1
fi

cd "$BUILD_DIR"
echo "Serving $BUILD_DIR on http://0.0.0.0:$PORT"
python3 -m http.server "$PORT"
