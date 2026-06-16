#!/usr/bin/env bash
# Rebuild compiled persona files: core.md + separator + each mode.
#
# Usage: ./rebuild.sh [--examples] [PERSONAS_DIR]
#   --examples   also compile the templates in personas/examples/
#
# By default only top-level personas/*.md are compiled. The files in
# personas/examples/ are TEMPLATES — copy one into personas/ first, or pass
# --examples to compile them directly. (This keeps ./rebuild.sh and the
# /switch rebuild command in agreement: both compile the same set.)
#
# Run after editing core.md or any mode file.

set -euo pipefail

WITH_EXAMPLES=0
DIR_ARG=""
for a in "$@"; do
  case "$a" in
    --examples) WITH_EXAMPLES=1 ;;
    *) DIR_ARG="$a" ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PERSONAS_DIR="${DIR_ARG:-$SCRIPT_DIR/../personas}"
PERSONAS_DIR="$(cd "$PERSONAS_DIR" && pwd)"
COMPILED_DIR="$PERSONAS_DIR/compiled"
VALIDATE="$SCRIPT_DIR/validate.sh"

if [[ ! -f "$PERSONAS_DIR/core.md" ]]; then
  echo "Error: core.md not found in $PERSONAS_DIR"
  exit 1
fi
mkdir -p "$COMPILED_DIR"

count=0
fails=0

compile_mode() {  # <mode_file> <label>
  local mode_file="$1" label="$2"
  local filename stem
  filename="$(basename "$mode_file")"
  stem="${filename%.md}"
  cat "$PERSONAS_DIR/core.md" <(printf '\n---\n\n') "$mode_file" > "$COMPILED_DIR/$filename"
  if "$VALIDATE" "$COMPILED_DIR/$filename" "$stem" >/dev/null 2>&1; then
    echo "  compiled/$filename$label"
  else
    echo "  compiled/$filename$label  -- validation issues:"
    "$VALIDATE" "$COMPILED_DIR/$filename" "$stem" | sed 's/^/    /' || true
    fails=$((fails + 1))
  fi
  count=$((count + 1))
}

for mode_file in "$PERSONAS_DIR"/*.md; do
  [[ -f "$mode_file" ]] || continue
  [[ "$(basename "$mode_file")" == "core.md" ]] && continue
  compile_mode "$mode_file" ""
done

if [[ "$WITH_EXAMPLES" -eq 1 && -d "$PERSONAS_DIR/examples" ]]; then
  for mode_file in "$PERSONAS_DIR/examples"/*.md; do
    [[ -f "$mode_file" ]] || continue
    compile_mode "$mode_file" " (from examples/)"
  done
fi

echo ""
if [[ "$count" -eq 0 ]]; then
  echo "No modes compiled — personas/ has no top-level *.md modes yet."
  echo "  - copy a template:        cp \"$PERSONAS_DIR/examples/developer.md\" \"$PERSONAS_DIR/\""
  echo "  - or compile examples:    $0 --examples"
  echo "  - or scaffold a starter:  $SCRIPT_DIR/init.sh"
  exit 0
fi
echo "Rebuilt $count persona(s) in $COMPILED_DIR"
if [[ "$fails" -gt 0 ]]; then
  echo "($fails persona(s) had validation failures — see above)"
  exit 1
fi
exit 0
