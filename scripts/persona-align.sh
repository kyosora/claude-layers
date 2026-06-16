#!/usr/bin/env bash
# Auto-align ~/.claude/CLAUDE.md to the persona for the current directory.
# The de-personalized, repo-first-class version of the old shell launcher.
#
# Opt-in. Wire it into a SessionStart hook (see .claude-plugin/hooks/) or call
# it from your shell launcher. It is built on deploy.sh, so every alignment is
# validated, backed up, atomic, and a TRUE silent no-op when already aligned.
#
# Persona selection precedence (first match wins; no match = do nothing):
#   1. ./.claude/persona     a file containing a mode name (per-project, committable)
#   2. cwd inside <marker>/<persona>/   marker defaults to "ws"
#                                       (override: CLAUDE_LAYERS_WS_MARKER)
#   3. no-op                 leaves CLAUDE.md untouched
#
# It NEVER copies on a speculative default — only on an explicit selection signal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Resolve PERSONAS_DIR the same way the /switch skill does.
if [[ -f "$HOME/.claude/persona-config" ]]; then
  PERSONAS_DIR="$(cat "$HOME/.claude/persona-config")"
else
  PERSONAS_DIR="$HOME/.claude/personas"
fi

mode=""
# (1) per-project selection file
if [[ -f "./.claude/persona" ]]; then
  mode="$(tr -d '[:space:]' < ./.claude/persona)"
fi
# (2) cwd marker dir, e.g. .../ws/<persona>/...
if [[ -z "$mode" ]]; then
  marker="${CLAUDE_LAYERS_WS_MARKER:-ws}"
  case "$PWD" in
    */"$marker"/*) mode="$(printf '%s' "$PWD" | sed -E "s#.*/$marker/([^/]+).*#\\1#")" ;;
  esac
fi
# (3) no explicit selection -> never touch CLAUDE.md
[[ -n "$mode" ]] || exit 0

compiled="$PERSONAS_DIR/compiled/$mode.md"
if [[ ! -f "$compiled" ]]; then
  echo "persona-align: no compiled persona '$mode' in $PERSONAS_DIR/compiled/ (skipped)" >&2
  exit 0
fi

# deploy.sh validates, backs up, writes atomically, and no-ops when aligned.
"$SCRIPT_DIR/deploy.sh" "$compiled"
