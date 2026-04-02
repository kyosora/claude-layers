---
name: switch
description: Layered CLAUDE.md switching via precompiled files.
---
# Persona Switch

Switch the active mode by replacing CLAUDE.md with a precompiled file (core + mode merged).

## Configuration

Before executing any case below, resolve the personas directory:
1. If `~/.claude/persona-config` exists, read its content as `PERSONAS_DIR`
2. Otherwise, use `~/.claude/personas/`

To set a custom path:
```bash
echo "/path/to/your/personas" > ~/.claude/persona-config
```

## Execution Steps

### Case A: No argument (list available)

If `$ARGUMENTS` is empty or unspecified, use Glob to list all `.md` files in `PERSONAS_DIR/compiled/`. Display filenames without `.md` as available modes, then stop.

### Case B: `rebuild`

If `$ARGUMENTS` is `rebuild`:

1. Use Glob to list all `.md` files in `PERSONAS_DIR/` (exclude core.md and compiled/)
2. Read `PERSONAS_DIR/core.md`
3. For each mode file:
   - Read the file
   - Concatenate: core.md content + `---` separator + mode file content
   - Write to `PERSONAS_DIR/compiled/[mode-name].md`
4. Report: "Recompiled [N] mode files."

### Case C: Temporary switch (`this session`)

If `$ARGUMENTS` contains "this session", "temp", or "temporary", extract the mode name from the remaining text:

1. Check if `PERSONAS_DIR/compiled/[mode-name].md` exists (use Glob)
2. If not, list available modes
3. If exists, Read the file content (do not copy)
4. Adopt that mode's behavior and skill bindings for this session
5. Report:
   ```
   Loaded [mode-name] mode for this session. CLAUDE.md unchanged.
   ```

### Case D: Permanent switch

If `$ARGUMENTS` is a specific mode name (e.g., `developer`, `writer`) without temporary keywords:

1. Check if `PERSONAS_DIR/compiled/$ARGUMENTS.md` exists (use Glob)
2. If not, list available modes
3. If exists, use Bash to copy:
   ```
   cp "PERSONAS_DIR/compiled/$ARGUMENTS.md" ~/.claude/CLAUDE.md
   ```
4. Report:
   ```
   Switched to [$ARGUMENTS] mode.
   Run /compact to clear old mode from context.
   ```

## Architecture

```
PERSONAS_DIR/                ← ~/.claude/personas/ by default
├── core.md                  ← Shared core (all modes inherit this)
├── developer.md             ← Developer mode specifics
├── writer.md                ← Writer mode specifics
└── compiled/                ← Precompiled files (core + mode merged)
    ├── developer.md         ← Ready to deploy as CLAUDE.md
    └── writer.md

~/.claude/
├── CLAUDE.md                ← Currently active mode (overwritten by /switch)
└── persona-config           ← Optional: custom personas directory path
```

## Notes

- After permanent switch, run `/compact` for the cleanest experience
- After editing core.md or any mode file, run `/switch rebuild` to recompile
- Cost per switch: ~50 tokens (one file copy)
