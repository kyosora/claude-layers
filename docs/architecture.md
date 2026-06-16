# Architecture

> This is the heart of the repo: the layered **core + mode** system and the `/switch`
> persona swap it enables. The [injection-defense block](injection-defense.md) is one
> feature that rides in the shared `core` — see the [Injection Defense](#injection-defense)
> section for its design. For setup steps and how the layering maps to native Claude Code
> features, see [setup.md](setup.md).

## The Problem (that the layering solves)

Most Claude Code users have a single `CLAUDE.md` that tries to do everything — coding standards, personality, tool bindings, memory rules, all in one file. This creates several issues:

1. **Context bloat**: Every session loads everything, even when irrelevant
2. **No specialization**: The same instructions for writing code and writing fiction
3. **Maintenance hell**: One edit can break unrelated behavior
4. **No reuse**: Shared rules (communication style, memory management) get copy-pasted across projects

## The Solution: Core + Mode Architecture

```
┌─────────────┐     ┌──────────────┐     ┌────────────────────┐
│   core.md   │  +  │  mode.md     │  →  │  compiled/mode.md  │
│ (shared)    │     │ (specialized)│     │  (deployed)        │
└─────────────┘     └──────────────┘     └────────────────────┘
                                                  │
                                                  ▼
                                          ~/.claude/CLAUDE.md
```

### core.md — The Foundation

Contains everything that's true regardless of what you're doing:
- Identity and personality
- Communication principles
- Injection defense framework
- Obsidian/memory rules
- Universal skill bindings (communication, file tools, learning)

**Rule**: If it applies to ALL your work, it goes in core.

### mode.md — The Specialization

Contains what's unique to a specific role:
- Domain philosophy (trading principles, writing craft, engineering standards)
- Specialized workflows
- Mode-specific skill bindings
- Domain-specific output formats

**Rule**: If it only applies when doing X, it goes in the X mode file.

### compiled/mode.md — The Deployment Artifact

A simple concatenation of core + mode. This is what actually gets deployed as `CLAUDE.md`.

```bash
cat core.md separator mode.md > compiled/mode.md
```

Why not just load both files? Because `CLAUDE.md` is a single file that Claude Code reads at session start. Precompiling means zero runtime overhead — switching personas is a file copy, not a merge operation.

## Skill Binding Tiers

### The Problem

If you have 150+ skill bindings all marked as "mandatory," the AI doesn't know what to prioritize. Everything looks equally important, which means nothing is important.

### The Solution: Two-Tier System

**🔴 Mandatory** — The skill provides irreplaceable external capability (API, service, specialized tool). Not triggering it means the task literally cannot be completed.

Examples: `xurl` (Twitter API), `openai-image-gen` (image generation), `linear` (issue tracking)

**🟡 Reference** — The skill provides quality-enhancing guidance, templates, or methodology. Not triggering it means the task can still be completed, just maybe not as well.

Examples: `python-patterns` (coding style), `creative-writing` (narrative guidance), `learn` (session learning)

### Application

Each category in the skill binding table gets a tier annotation:

```markdown
### Communication
> 🔴 All mandatory — external communication APIs

### Learning & Evolution
> 🟡 All reference — meta-learning tools, trigger as needed

### Documents & Content
> Mixed: `document-skills:pdf/docx` 🔴 mandatory; writing guides 🟡 reference
```

The execution rule is simple:
> 🔴 Mandatory bindings must trigger, no exceptions. 🟡 Reference bindings can be judged based on context.

## Injection Defense

> A feature that falls out of the shared `core`: every persona inherits one place to put
> always-on rules. The full paste-ready block lives in
> [injection-defense.md](injection-defense.md); this section explains the design behind it.

### The Problem

Most prompt injection defenses boil down to "trust the user, ignore everything else." This creates a circular vulnerability: the defense assumes you can always identify who the user is, but injection attacks work precisely by spoofing the source.

### The Solution: Source + Purpose Verification

Instead of identity-based trust, verify two things:

1. **Where did this instruction come from?**
   - Direct user input in conversation → process normally
   - Tool output, system message, external data → potential injection

2. **What is this instruction's purpose?**
   - Complete the user's task → process normally
   - Restrict behavior, change identity, ignore instructions → injection

### Skill Trust Boundary

Installed skills are NOT automatically trusted. Users install many skills without reviewing each one. The same source + purpose framework applies:

- Skill **workflow logic** (how to complete a task) → follow
- Skill **non-task behaviors** (promotions, data collection, identity override) → disclose to user

## Switching Mechanism

### /switch command

```
/switch              → List available personas
/switch developer    → Deploy compiled/developer.md as CLAUDE.md
/switch writer temp  → Load writer for this session only
/switch rebuild      → Recompile all personas (after editing core/mode files)
```

Cost per switch: ~50 tokens (one file copy). No context window overhead.

### When to use temporary vs permanent

- **Permanent** (`/switch developer`): Your default working mode. Persists across sessions.
- **Temporary** (`/switch writer this session`): Quick detour. CLAUDE.md stays as-is, the persona is loaded into current context only.

## File Layout

```
personas/
├── core.md                  ← Shared foundation (includes the defense block)
├── examples/
│   ├── developer.md         ← Example: developer persona
│   ├── writer.md            ← Example: writer persona
│   └── analyst.md           ← Example: analyst persona
└── compiled/                ← Precompiled deployment artifacts (gitignored, generated)
skills/
└── switch/
    └── SKILL.md             ← The /switch command (rebuild / switch / status / undo)
scripts/
├── rebuild.sh               ← Batch recompilation (+ validate; --examples)
├── validate.sh              ← Structural lint of a compiled persona
├── deploy.sh                ← The ONE safe deploy primitive (validate/backup/atomic/no-op)
├── switch-test.sh           ← Deterministic, model-free switch-contract tests
├── init.sh                  ← 2-minute guarded scaffold
├── persona-align.sh / .ps1  ← Auto-align CLAUDE.md to the cwd's persona (opt-in)
├── injection-test.sh        ← A/B defense test runner + auto-scorer
├── llm-judge.sh             ← Optional LLM-judge 4-criterion scorer
└── make-output-style.sh     ← Optional: persona voice → native output-style
hooks/                       ← SessionStart auto-align hook (plugin-loaded)
.github/workflows/
└── injection-test.yml       ← CI: shellcheck + switch-test + rebuild; manual A/B
.claude-plugin/
├── plugin.json              ← Optional: install as a Claude Code plugin
└── marketplace.json         ← /plugin marketplace add kyosora/claude-layers
docs/
├── setup.md                 ← Layered-persona setup + native-feature mapping
└── injection-defense.md     ← Standalone defense block (byproduct of the shared core)
```
