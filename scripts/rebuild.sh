#!/usr/bin/env bash
# Rebuild all compiled persona files
# Usage: ./rebuild.sh [PERSONAS_DIR]
#
# Concatenates core.md + separator + each mode file into compiled/
# Run this after editing core.md or any mode file.

set -euo pipefail

PERSONAS_DIR="${1:-$(dirname "$0")/../personas}"
PERSONAS_DIR="$(cd "$PERSONAS_DIR" && pwd)"
COMPILED_DIR="$PERSONAS_DIR/compiled"

# Verify core.md exists
if [[ ! -f "$PERSONAS_DIR/core.md" ]]; then
  echo "Error: core.md not found in $PERSONAS_DIR"
  exit 1
fi

# Create compiled directory if needed
mkdir -p "$COMPILED_DIR"

# Find all mode files (exclude core.md and compiled/)
count=0
for mode_file in "$PERSONAS_DIR"/*.md; do
  filename="$(basename "$mode_file")"

  # Skip core.md
  [[ "$filename" == "core.md" ]] && continue

  # Compile: core + separator + mode
  cat "$PERSONAS_DIR/core.md" <(printf '\n---\n\n') "$mode_file" > "$COMPILED_DIR/$filename"

  echo "  compiled/$filename"
  count=$((count + 1))
done

# Also compile from examples/ if present
if [[ -d "$PERSONAS_DIR/examples" ]]; then
  for mode_file in "$PERSONAS_DIR/examples"/*.md; do
    [[ ! -f "$mode_file" ]] && continue
    filename="$(basename "$mode_file")"

    cat "$PERSONAS_DIR/core.md" <(printf '\n---\n\n') "$mode_file" > "$COMPILED_DIR/$filename"

    echo "  compiled/$filename (from examples/)"
    count=$((count + 1))
  done
fi

echo ""
echo "Rebuilt $count persona(s) in $COMPILED_DIR"
