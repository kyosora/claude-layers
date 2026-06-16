#!/usr/bin/env bash
# SessionStart hook: align ~/.claude/CLAUDE.md to the current directory's persona.
#
# Strictly opt-in by behavior: persona-align.sh is a NO-OP unless there is an
# explicit selection signal (a ./.claude/persona file or a cwd inside
# <marker>/<persona>/). Installing the plugin alone changes nothing until you opt
# in. Never fails the session — alignment errors are swallowed.
#
# Timing note: this writes the file Claude reads at startup; depending on your
# Claude Code version the change may take effect on the NEXT session.

set -euo pipefail
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
"$HOOK_DIR/../scripts/persona-align.sh" || true
