#!/usr/bin/env bash
# Deterministic, model-free test of the switch/layering CONTRACT.
# No API key, no model — pure file operations, runs in well under a second.
# Exit 0 = all pass, 1 = any failure. Mirrors injection-test.sh's exit contract.
#
# This is the headline's proof, the way injection-test.sh is the byproduct's.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
ok() { printf "  PASS  %s\n" "$1"; PASS=$((PASS + 1)); }
no() { printf "  FAIL  %s\n" "$1"; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PDIR="$WORK/personas"
mkdir -p "$PDIR/examples"
printf '# Core\n<!-- shared core -->\nshared-core-line\n' > "$PDIR/core.md"
printf '# Dev\n<!-- CURRENT_MODE: dev -->\ndev-body\n' > "$PDIR/dev.md"
printf '# Writer\n<!-- CURRENT_MODE: writer -->\nwriter-body\n' > "$PDIR/examples/writer.md"

echo "=== rebuild contract ==="
"$SCRIPT_DIR/rebuild.sh" "$PDIR" >/dev/null

cat "$PDIR/core.md" <(printf '\n---\n\n') "$PDIR/dev.md" > "$WORK/expected"
if cmp -s "$PDIR/compiled/dev.md" "$WORK/expected"; then
  ok "rebuild: compiled == core + separator + mode (byte-for-byte)"
else
  no "rebuild byte-correctness"
fi

if [[ ! -f "$PDIR/compiled/writer.md" ]]; then
  ok "rebuild: examples/ excluded by default (matches /switch rebuild)"
else
  no "rebuild compiled an example by default"
fi

"$SCRIPT_DIR/rebuild.sh" --examples "$PDIR" >/dev/null
if [[ -f "$PDIR/compiled/writer.md" ]]; then
  ok "rebuild --examples: templates compiled on request"
else
  no "rebuild --examples did not compile the example"
fi

cp "$PDIR/compiled/dev.md" "$WORK/first"
"$SCRIPT_DIR/rebuild.sh" --examples "$PDIR" >/dev/null
if cmp -s "$PDIR/compiled/dev.md" "$WORK/first"; then
  ok "rebuild: idempotent (re-run yields identical bytes)"
else
  no "rebuild not idempotent"
fi

EMPTY="$WORK/empty"
mkdir -p "$EMPTY"
printf '# Core only\n' > "$EMPTY/core.md"
set +e
out="$("$SCRIPT_DIR/rebuild.sh" "$EMPTY" 2>&1)"
rc=$?
set -e
if [[ $rc -eq 0 ]] && printf '%s' "$out" | grep -q "No modes compiled"; then
  ok "rebuild: no top-level modes -> exit 0 with a hint"
else
  no "rebuild empty-modes behavior (rc=$rc)"
fi

echo ""
echo "=== deploy contract (sandboxed HOME) ==="
export HOME="$WORK/home"
mkdir -p "$HOME/.claude"
SRC="$PDIR/compiled/dev.md"

"$SCRIPT_DIR/deploy.sh" "$SRC" >/dev/null
if cmp -s "$SRC" "$HOME/.claude/CLAUDE.md"; then
  ok "deploy: CLAUDE.md == the compiled persona"
else
  no "deploy did not land the file"
fi

before="$(cksum < "$HOME/.claude/CLAUDE.md")"
"$SCRIPT_DIR/deploy.sh" "$SRC" >/dev/null
after="$(cksum < "$HOME/.claude/CLAUDE.md")"
if [[ "$before" == "$after" ]]; then
  ok "deploy: silent no-op when already aligned"
else
  no "deploy rewrote an already-identical file"
fi

printf 'SENTINEL-DO-NOT-LOSE\n' > "$HOME/.claude/CLAUDE.md"
"$SCRIPT_DIR/deploy.sh" --check "$SRC" >/dev/null
if grep -q SENTINEL "$HOME/.claude/CLAUDE.md"; then
  ok "deploy --check: read-only, leaves CLAUDE.md untouched (like a temp switch)"
else
  no "deploy --check mutated CLAUDE.md"
fi

"$SCRIPT_DIR/deploy.sh" "$SRC" >/dev/null   # overwrites SENTINEL, backing it up
"$SCRIPT_DIR/deploy.sh" --undo >/dev/null
if grep -q SENTINEL "$HOME/.claude/CLAUDE.md"; then
  ok "deploy --undo: restores the previous CLAUDE.md"
else
  no "deploy --undo did not restore the backup"
fi

BAD="$WORK/bad.md"
printf '# no marker here\n' > "$BAD"
cp "$SRC" "$HOME/.claude/CLAUDE.md"
if "$SCRIPT_DIR/deploy.sh" "$BAD" >/dev/null 2>&1; then
  no "deploy accepted an invalid persona"
elif cmp -s "$SRC" "$HOME/.claude/CLAUDE.md"; then
  ok "deploy: refuses an invalid source, CLAUDE.md unchanged"
else
  no "deploy mutated CLAUDE.md while refusing an invalid source"
fi

echo ""
echo "=== validate contract ==="
if "$SCRIPT_DIR/validate.sh" "$SRC" dev >/dev/null 2>&1; then
  ok "validate: accepts a well-formed persona"
else
  no "validate rejected a good persona"
fi
if "$SCRIPT_DIR/validate.sh" "$BAD" >/dev/null 2>&1; then
  no "validate accepted a marker-less file"
else
  ok "validate: rejects a missing CURRENT_MODE marker"
fi
if "$SCRIPT_DIR/validate.sh" "$SRC" writer >/dev/null 2>&1; then
  no "validate accepted a mode/filename mismatch"
else
  ok "validate: rejects a mode/filename mismatch"
fi

echo ""
echo "────────────────────────"
echo "PASS: $PASS / $((PASS + FAIL))"
echo "FAIL: $FAIL"
echo "────────────────────────"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
