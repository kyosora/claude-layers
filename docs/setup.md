# Setup & the Layered Persona System

The full guide to the heart of this repo: a shared `core` + swappable `mode`s, precompiled
into one deployable `CLAUDE.md` per persona and switched with `/switch`. For the conceptual
design, see [architecture.md](architecture.md).

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

## How this relates to native features

Some of what the layering does now overlaps platform-native features. Worth knowing so you
can pick the right tool — and so you know where the layering still earns its keep:

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

The injection-defense block is already in `core.md` (and mirrored as the standalone
[injection-defense.md](injection-defense.md)); every compiled persona inherits it.

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
| `/switch developer` | Permanently switch — validated, backed up, atomic (via `deploy.sh`) |
| `/switch writer this session` | Temporary switch (`CLAUDE.md` unchanged) |
| `/switch status` | Report the active mode (reads the `CURRENT_MODE` marker) |
| `/switch undo` | Restore the previous `CLAUDE.md` from backup |
| `/switch rebuild` | Recompile all modes after editing core or mode files |

The underlying primitives are scriptable too: `scripts/deploy.sh <compiled-file>`
(deploy), `--check` (validate only, read-only), `--status`, `--undo`.

## Proving the switch flow

`scripts/switch-test.sh` is a deterministic, model-free test of the switch contract
(runs in CI): rebuild is byte-correct (`core + separator + mode`), a permanent switch
deploys the exact file, a temp switch / `--check` leaves `CLAUDE.md` untouched, deploy
is a no-op when already aligned, `--undo` restores the backup, and `validate.sh`
rejects malformed personas. Run it anytime: `./scripts/switch-test.sh`.

## Automatic switching (opt-in SessionStart hook)

Instead of typing `/switch` per project, let the persona follow your directory:

- **Per-project:** commit a `./.claude/persona` file containing a mode name. Opening
  that repo aligns `CLAUDE.md` to it.
- **By convention:** work under a `…/ws/<persona>/` tree (the marker dir is
  configurable via `CLAUDE_LAYERS_WS_MARKER`).

`scripts/persona-align.sh` (POSIX) / `scripts/persona-align.ps1` (Windows) resolve the
selection and deploy through `deploy.sh`, so every alignment is validated, backed up,
and a **true silent no-op when already aligned**. It NEVER copies on a speculative
default — only on an explicit selection signal.

The plugin ships this as a **SessionStart hook** (`hooks/hooks.json` →
`hooks/session-start.sh`), so `/plugin marketplace add kyosora/claude-layers` wires up
auto-switching with no shell-profile editing. Installing the plugin changes nothing
until you opt in (no `.claude/persona`, no `ws/` cwd → no-op). Timing note: the hook
writes the file Claude reads at startup, so depending on your Claude Code version the
change may take effect on the next session.

**Division of labor:** SessionStart hook = automatic, project-driven alignment;
`/switch` = manual / temporary override and rebuild; `make-output-style.sh` = optional
voice-only native bridge. `CLAUDE.md` remains the single file Claude loads.

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
personas/
├── core.md                ← shared foundation (incl. the defense block)
├── examples/              ← developer / writer / analyst templates
└── compiled/              ← precompiled deployment artifacts (gitignored, generated)
skills/switch/SKILL.md     ← the /switch command (rebuild / switch / status / undo)
scripts/
├── rebuild.sh             ← batch recompilation (+ per-mode validate; --examples)
├── validate.sh            ← structural lint of a compiled persona
├── deploy.sh              ← the ONE safe deploy: validate → backup → atomic → no-op
├── switch-test.sh         ← deterministic, model-free contract tests (CI-gated)
├── init.sh                ← 2-minute guarded scaffold
├── persona-align.sh/.ps1  ← auto-align CLAUDE.md to the cwd's persona (opt-in)
├── injection-test.sh      ← A/B defense test runner + auto-scorer
├── llm-judge.sh           ← optional LLM-judge 4-criterion scorer
└── make-output-style.sh   ← optional: persona voice → native output-style
hooks/
├── hooks.json             ← SessionStart auto-align hook (plugin-loaded)
├── run-hook.cmd           ← cross-platform polyglot wrapper
└── session-start.sh       ← calls persona-align.sh
docs/injection-defense.md  ← the standalone defense block (a byproduct of the shared core)
.claude-plugin/
├── plugin.json            ← optional: install as a Claude Code plugin
└── marketplace.json       ← /plugin marketplace add kyosora/claude-layers
```
