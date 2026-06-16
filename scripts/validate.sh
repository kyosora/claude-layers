#!/usr/bin/env bash
# Validate a compiled persona file — structural lint for the layering.
#
# Usage:
#   ./scripts/validate.sh <compiled-file> [expected-mode]
#     [expected-mode]  if given, the <!-- CURRENT_MODE: x --> marker must equal it
#   --strict           treat WARN as failure (for CI)
#
# Exit: 0 = ok (or only warnings), 1 = a hard failure.
# Hard FAIL:  empty file; zero or multiple CURRENT_MODE markers; marker != expected.
# WARN:       duplicate `## ` section headings (core↔mode collision); over line budget.
#
# Env: CLAUDE_LAYERS_LINE_BUDGET (default 600) — soft cap that triggers a WARN.

set -euo pipefail

STRICT=0
ARGS=()
for a in "$@"; do
  if [[ "$a" == "--strict" ]]; then STRICT=1; else ARGS+=("$a"); fi
done
FILE="${ARGS[0]:-}"
EXPECT="${ARGS[1]:-}"
BUDGET="${CLAUDE_LAYERS_LINE_BUDGET:-600}"

if [[ -z "$FILE" ]]; then
  echo "Usage: $0 <compiled-file> [expected-mode] [--strict]"
  exit 1
fi

fails=0
warns=0
fail() { printf "  FAIL  %s\n" "$1"; fails=$((fails + 1)); }
warn() { printf "  WARN  %s\n" "$1"; warns=$((warns + 1)); }

if [[ ! -s "$FILE" ]]; then
  fail "missing or empty: $FILE"
  echo "validate: $FILE → 1 fail"
  exit 1
fi

# Exactly one CURRENT_MODE marker.
markers=$(grep -cE '<!--[[:space:]]*CURRENT_MODE:' "$FILE" || true)
if [[ "$markers" -eq 0 ]]; then
  fail "no <!-- CURRENT_MODE: x --> marker (which persona is this?)"
elif [[ "$markers" -gt 1 ]]; then
  fail "$markers CURRENT_MODE markers (must be exactly 1)"
elif [[ -n "$EXPECT" ]]; then
  got=$(grep -oE '<!--[[:space:]]*CURRENT_MODE:[[:space:]]*[^ ]+' "$FILE" | grep -oE '[^ ]+$' | head -1)
  [[ "$got" == "$EXPECT" ]] || fail "CURRENT_MODE is '$got' but expected '$EXPECT' (mode/filename mismatch)"
fi

# Duplicate section headings = core↔mode collision (the canonical silent failure).
dupes=$(grep -E '^## ' "$FILE" | sort | uniq -d || true)
if [[ -n "$dupes" ]]; then
  while IFS= read -r h; do warn "duplicate section heading: $h"; done <<< "$dupes"
fi

# Lean budget.
lines=$(wc -l < "$FILE" | tr -d ' ')
[[ "$lines" -gt "$BUDGET" ]] && warn "compiled file is $lines lines (> budget $BUDGET; keep modes lean)"

printf "validate: %s → %d fail, %d warn\n" "$FILE" "$fails" "$warns"
if [[ "$fails" -gt 0 ]]; then exit 1; fi
if [[ "$STRICT" -eq 1 && "$warns" -gt 0 ]]; then exit 1; fi
exit 0
