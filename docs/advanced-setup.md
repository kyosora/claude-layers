# Advanced: Layered Personas (optional)

> The headline of this repo is the [injection defense block](../DEFENSE.md). You do **not**
> need any of this page to use it. This is the optional layering system for people who run
> multiple Claude personas and want one self-contained `CLAUDE.md` per mode.

## What it is

```
core.md (shared identity, memory rules, universal skills, the injection-defense block)
   +
mode.md (domain philosophy, specialized workflows, mode-specific skills)
   ↓
compiled/mode.md  →  deployed as ~/.claude/CLAUDE.md
```

Every mode inherits `core`. Editing `core` updates all modes on the next rebuild. The
compiled file is a plain concatenation, so deploying a persona is a single file copy with
zero runtime merge cost.

**Rule of thumb:** applies to ALL your work → `core`. Only applies when doing X → mode `X`.

## Should you use this, or a native feature?

This system predates several now-native Claude Code capabilities and overlaps them. Prefer
the native mechanism when one exists; reach for the layering only for what it still does
uniquely.

| This repo | Native equivalent (2026) | Reach for the layering when… |
|-----------|--------------------------|------------------------------|
| `core.md` + `mode.md` precompile | output-styles, subagents | you want one self-contained `CLAUDE.md` file, zero runtime merge |
| `/switch` (copies the compiled file into `~/.claude/CLAUDE.md`) | `/output-style` | you specifically want single-file persona swaps |
| Skill trigger tables | skill frontmatter discovery | you need cross-skill **priority** (the 🔴/🟡 rule), which frontmatter can't express |
| `rebuild.sh` concatenation | plugins / marketplaces | you're distributing to others (a [plugin manifest](../.claude-plugin/plugin.json) is included) |

**Caveat on output-styles:** an output-style *replaces* the built-in system prompt, while
`CLAUDE.md` is *appended* to it. If you port a persona to an output-style, move only the
identity/voice half there and keep rules, memory, and the defense block in `CLAUDE.md` —
otherwise you silently drop Claude Code's built-in coding/verification instructions.

`scripts/make-output-style.sh` does exactly that split for you — it extracts only the
persona's leading identity block and writes a native output-style, leaving `/switch` and
`CLAUDE.md` untouched:

```bash
./scripts/make-output-style.sh developer   # → ~/.claude/output-styles/developer.md
/output-style developer                     # native voice swap; rules stay in CLAUDE.md
```

## Setup

### 1. Clone and customize the core

```bash
git clone https://github.com/kyosora/claude-layers.git
cd claude-layers
```

Edit `personas/core.md` — your shared foundation. Replace the `[PLACEHOLDERS]`:

- Identity and personality
- Obsidian vault path (or remove the section)
- Universal skill bindings with 🔴/🟡 tiers
- Language preferences

The injection-defense block is already in `core.md` (and mirrored in
[DEFENSE.md](../DEFENSE.md)); every compiled persona inherits it.

### 2. Create your modes

Use `personas/examples/` as starting points. Each mode file only needs what's **different**
from core:

```bash
cp personas/examples/developer.md personas/developer.md
# edit to fit
```

### 3. Build

```bash
chmod +x scripts/rebuild.sh
./scripts/rebuild.sh
```

This concatenates `core.md` + each mode into `personas/compiled/`. (Run it after editing
`core.md` or any mode file.)

### 4. Install the switch skill

```bash
cp -r skills/switch ~/.claude/skills/switch
```

### 5. Deploy

```
/switch developer
```

`~/.claude/CLAUDE.md` is now the compiled developer mode.

## Commands

| Command | Effect |
|---------|--------|
| `/switch` | List available modes |
| `/switch developer` | Permanently switch (overwrites `CLAUDE.md`) |
| `/switch writer this session` | Temporary switch (`CLAUDE.md` unchanged) |
| `/switch rebuild` | Recompile all modes after editing core or mode files |

## Creating your own mode

A mode file only needs what's **different** from core:

```markdown
# [Mode Name]

<!-- CURRENT_MODE: [mode-id] -->

[One paragraph: who you are in this mode]

---

## [Domain] Philosophy
[Specialized principles]

## [Domain]-Specific Skill Bindings
> [Tier annotation]

| Trigger | Skill | Description |
|---------|-------|-------------|

> Universal bindings are in core.

## Workflow
[Mode-specific procedures]
```

**Keep it lean.** A mode with 3 philosophy points, 1 skill table, and 2 workflows beats
500 lines that repeat half of core.

## File layout

```
DEFENSE.md                 ← the paste-ready injection-defense block (the headline)
personas/
├── core.md                ← shared foundation (incl. the defense block)
├── examples/              ← developer / writer / analyst templates
└── compiled/              ← precompiled deployment artifacts (gitignored, generated)
skills/switch/SKILL.md     ← the /switch command
scripts/
├── rebuild.sh             ← batch recompilation
├── injection-test.sh      ← A/B defense test runner + auto-scorer
├── llm-judge.sh           ← optional LLM-judge 4-criterion scorer
└── make-output-style.sh   ← optional: persona voice → native output-style
.claude-plugin/
├── plugin.json            ← optional: install as a Claude Code plugin
└── marketplace.json       ← /plugin marketplace add kyosora/claude-layers
```
