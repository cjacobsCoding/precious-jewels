#!/usr/bin/env bash
set -euo pipefail

# Exports the Godot project to HTML5 using a local `godot` binary or Docker fallback.
# Requires an export preset named "HTML5" in `export_presets.cfg`.

PROJECT_DIR="$(pwd)"
BUILD_DIR="$PROJECT_DIR/builds/html5"
PRESET_NAME="HTML5"

mkdir -p "$BUILD_DIR"

if [ -n "${GODOT_CMD:-}" ] && [ -x "${GODOT_CMD}" ]; then
  echo "Using GODOT_CMD ($GODOT_CMD) to export..."
  "$GODOT_CMD" --path "$PROJECT_DIR" --export "$PRESET_NAME" "$BUILD_DIR/index.html"
  exit 0
fi

if [ -x "./godot" ]; then
  echo "Using local ./godot binary to export..."
  ./godot --headless --path "$PROJECT_DIR" --export-release "$PRESET_NAME" "$BUILD_DIR/index.html"
  exit 0
fi

if command -v godot >/dev/null 2>&1; then
  echo "Using system 'godot' binary to export..."
  godot --headless --path "$PROJECT_DIR" --export-release "$PRESET_NAME" "$BUILD_DIR/index.html"
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Neither 'godot' nor 'docker' found. Install Godot editor or Docker and try again."
  exit 2
fi

echo "Local godot not found, trying Docker fallback (requires Docker)..."

# If user set GODOT_IMAGE explicitly, try that first.
if [ -n "${GODOT_IMAGE:-}" ]; then
  IMAGES=("${GODOT_IMAGE}")
else
  IMAGES=(
    "ghcr.io/godotengine/godot:4.2-stable"
    "ghcr.io/godotengine/godot:4.1-stable"
    "godotengine/godot:4.1"
    "godotengine/godot:3.5"
    "godot:4.1"
    "godot:3.5"
  )
fi

for IMG in "${IMAGES[@]}"; do
  echo "Trying Docker image: $IMG"
      if docker run --rm -u "$(id -u):$(id -g)" -v "$PROJECT_DIR":/project -w /project "$IMG" \
        godot --headless --path /project --export-release "$PRESET_NAME" /project/builds/html5/index.html; then
    echo "Export succeeded using $IMG"
    exit 0
  else
    echo "Export failed with $IMG, trying next image..."
  fi
done

echo "All Docker image attempts failed. You can set a working image with GODOT_IMAGE and retry, or install a local 'godot' binary."
exit 3
