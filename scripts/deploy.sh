#!/usr/bin/env bash
# The ONE safe way a compiled persona becomes ~/.claude/CLAUDE.md.
# validate → back up current → atomic write → no-op when already identical.
# A switch is still basically a file copy — this just makes it non-destructive.
#
# Usage:
#   deploy.sh <compiled-file>   Deploy it as ~/.claude/CLAUDE.md (atomic, backed up)
#   deploy.sh --check <file>    Validate only; never writes CLAUDE.md (read-only)
#   deploy.sh --status          Print the active mode (from the live CLAUDE.md marker)
#   deploy.sh --undo            Restore the most recent backup
#
# State lives under ~/.claude/.claude-layers/ (trivially deletable). HOME is
# honored, so tests can point it at a sandbox.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/CLAUDE.md"
STATE="$HOME/.claude/.claude-layers"
BAK="$STATE/CLAUDE.md.bak"

marker() { grep -oE '<!--[[:space:]]*CURRENT_MODE:[[:space:]]*[^ ]+' "$1" 2>/dev/null | grep -oE '[^ ]+$' | head -1; }

case "${1:-}" in
  --status)
    if [[ -f "$TARGET" ]]; then
      m="$(marker "$TARGET" || true)"; echo "Active mode: ${m:-unknown}"
    else echo "No ~/.claude/CLAUDE.md deployed."; fi
    exit 0 ;;
  --undo)
    [[ -f "$BAK" ]] || { echo "No backup to undo."; exit 1; }
    mkdir -p "$(dirname "$TARGET")"
    cp "$BAK" "$TARGET.tmp.$$" && mv "$TARGET.tmp.$$" "$TARGET"
    echo "Reverted CLAUDE.md to the previous backup (mode: $(marker "$TARGET" || echo unknown))."
    exit 0 ;;
  --check) CHECK=1; SRC="${2:-}" ;;
  "") echo "Usage: $0 <compiled-file> | --check <file> | --status | --undo"; exit 1 ;;
  *) CHECK=0; SRC="$1" ;;
esac

[[ -n "${SRC:-}" ]] || { echo "Error: no source file given."; exit 1; }
# Validate the source before it can ever overwrite a live CLAUDE.md.
"$SCRIPT_DIR/validate.sh" "$SRC" >/dev/null 2>&1 || { "$SCRIPT_DIR/validate.sh" "$SRC"; echo "Refusing to deploy an invalid persona."; exit 1; }

if [[ "$CHECK" -eq 1 ]]; then echo "OK: $SRC is valid (not deployed)."; exit 0; fi

mkdir -p "$STATE" "$(dirname "$TARGET")"
if [[ -f "$TARGET" ]] && cmp -s "$SRC" "$TARGET"; then
  exit 0   # already aligned — true silent no-op (kills resync churn for auto-align)
fi
[[ -f "$TARGET" ]] && cp "$TARGET" "$BAK"          # one recovery point
cp "$SRC" "$TARGET.tmp.$$" && mv "$TARGET.tmp.$$" "$TARGET"   # atomic
echo "Deployed $(marker "$SRC" || basename "$SRC") → $TARGET"
