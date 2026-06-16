#!/usr/bin/env bash
# Scaffold a working layered-persona setup in ~2 minutes.
#
# Usage: ./scripts/init.sh [PERSONAS_DIR] [--force]
#   PERSONAS_DIR  where your personas live (default: ~/.claude/personas)
#   --force       overwrite an existing core.md / persona-config
#
# Non-destructive by default: refuses to clobber an existing core.md or
# persona-config without --force, and backs up any existing ~/.claude/CLAUDE.md.

set -euo pipefail

FORCE=0
DEST=""
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    *) DEST="$a" ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${DEST:-$HOME/.claude/personas}"
CONFIG="$HOME/.claude/persona-config"

mkdir -p "$DEST"
if [[ -f "$DEST/core.md" && "$FORCE" -ne 1 ]]; then
  echo "Refusing: $DEST/core.md already exists. Re-run with --force to overwrite."
  exit 1
fi

# 1. Shared core + one starter mode (instantiated from the developer template).
cp "$REPO/personas/core.md" "$DEST/core.md"
cp "$REPO/personas/examples/developer.md" "$DEST/developer.md"
echo "Scaffolded $DEST/{core.md, developer.md}"

# 2. Compile.
"$SCRIPT_DIR/rebuild.sh" "$DEST"

# 3. Point persona-config at it (guarded).
if [[ -f "$CONFIG" && "$FORCE" -ne 1 ]]; then
  echo "Note: $CONFIG already exists, left unchanged (use --force to repoint)."
else
  mkdir -p "$(dirname "$CONFIG")"
  printf '%s\n' "$DEST" > "$CONFIG"
  echo "Pointed $CONFIG -> $DEST"
fi

# 4. Back up any existing CLAUDE.md so the next switch is non-destructive.
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [[ -f "$CLAUDE_MD" ]]; then
  cp "$CLAUDE_MD" "$CLAUDE_MD.pre-claude-layers.bak"
  echo "Backed up existing CLAUDE.md -> $CLAUDE_MD.pre-claude-layers.bak"
fi

echo ""
echo "Done. Deploy the starter persona with:"
echo "  $SCRIPT_DIR/deploy.sh \"$DEST/compiled/developer.md\""
echo "or, with the switch skill installed:  /switch developer"
