#!/usr/bin/env bash
# Generate a Claude Code output-style from a persona's IDENTITY half — opt-in,
# non-destructive, and deliberately partial.
#
# Why only the identity half: an output-style REPLACES the built-in system
# prompt, whereas CLAUDE.md is APPENDED to it. If you dumped a whole persona
# (rules, memory, the injection-defense block) into an output-style, you would
# silently drop Claude Code's built-in coding/verification instructions — a
# never-break-userspace regression. So this script extracts ONLY the leading
# identity/voice block (everything before the first `---` separator, per the
# mode-file template) and leaves rules/memory/defense to live in CLAUDE.md.
#
# This does NOT touch ~/.claude/CLAUDE.md and does NOT replace /switch. It's an
# additive way to get the persona's *voice* via the native /output-style switch.
#
# Usage:
#   ./scripts/make-output-style.sh developer
#   ./scripts/make-output-style.sh writer ~/.claude/output-styles

set -euo pipefail

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
  echo "Usage: $0 <mode> [output-styles-dir]"
  echo "  Looks for personas/<mode>.md, then personas/examples/<mode>.md"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PERSONAS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/personas"
OUT_DIR="${2:-$HOME/.claude/output-styles}"

# Find the mode file: project mode first, then examples/.
SRC=""
for candidate in "$PERSONAS_DIR/$MODE.md" "$PERSONAS_DIR/examples/$MODE.md"; do
  if [[ -f "$candidate" ]]; then SRC="$candidate"; break; fi
done
if [[ -z "$SRC" ]]; then
  echo "Error: no persona file for '$MODE' (looked in personas/ and personas/examples/)."
  exit 1
fi

mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/$MODE.md"

# Identity = everything up to (not including) the first line that is exactly `---`.
identity="$(awk 'BEGIN{f=0} /^---[[:space:]]*$/{f=1; exit} {print}' "$SRC")"

{
  printf -- '---\n'
  printf 'name: %s\n' "$MODE"
  printf 'description: %s persona voice (identity only — rules/memory stay in CLAUDE.md)\n' "$MODE"
  printf -- '---\n\n'
  printf '%s\n' "$identity"
} > "$OUT"

echo "Wrote $OUT"
echo "Switch to it with:  /output-style $MODE"
echo "Note: this carries the persona's VOICE only. Keep your rules, memory, and the"
echo "injection-defense block in CLAUDE.md — output-styles replace the system prompt."
