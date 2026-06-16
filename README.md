# Claude Layers

**English** | [繁體中文](README.zh-TW.md)

**A layered architecture for your `CLAUDE.md` — the shareable, generalized form of a
persona-switch setup.** Define a shared `core`, layer domain `modes` on top, precompile
each into a single deployable `CLAUDE.md`, and swap between them with `/switch`.

This started as one personal `/switch` skill. The repo is the abstraction of it: the
layering and tiering that make persona switching actually work, packaged so anyone can
adopt it.

## The problem

Your `CLAUDE.md` is 300+ lines and everything is marked "mandatory." Shared rules
(identity, memory, communication bindings) get copy-pasted across every context, so one
edit means updating five files by hand — and the AI can't tell what to prioritize when
every skill is "must use."

Layering fixes that. Persona switching is the main application; you get skill-priority
tiers and a shared injection-defense block along the way.

## 1. Core + mode architecture

```
core.md  (shared identity, memory rules, universal skills, injection-defense block)
   +
mode.md  (domain philosophy, specialized workflows, mode-specific skills)
   ↓
compiled/mode.md  →  deployed as ~/.claude/CLAUDE.md
```

Every mode inherits `core`. Edit `core` once → all modes update on the next rebuild. The
compiled file is a plain concatenation, so deploying a persona is a single file copy with
**zero runtime merge cost**.

**Rule of thumb:** applies to ALL your work → `core`. Only applies when doing X → mode `X`.

→ [Architecture deep-dive](docs/architecture.md) · [Setup guide](docs/setup.md)

## 2. Persona switching (`/switch`)

| Command | Effect |
|---------|--------|
| `/switch` | List available modes |
| `/switch developer` | Permanently switch (overwrites `CLAUDE.md`) |
| `/switch writer this session` | Temporary switch (`CLAUDE.md` unchanged) |
| `/switch rebuild` | Recompile all modes after editing core or mode files |

Cost per switch: ~50 tokens (one file copy). No context-window overhead.

## 3. Skill priority tiers

When 150 skills are all marked "mandatory," nothing is — the AI burns tokens evaluating
skills it doesn't need. Two tiers fix it, and you can adopt this in your existing
`CLAUDE.md` without anything else from this repo:

- **🔴 Mandatory** — wraps an external API/service. Not triggering = the task can't be done.
- **🟡 Reference** — provides guidance/templates. Not triggering = lower quality, not failure.

> 🔴 Mandatory bindings must trigger, no exceptions. 🟡 Reference bindings are judged by
> context. This is a priority/conflict-resolution rule that *complements* skill frontmatter
> discovery — it doesn't replace it.

## Byproduct: a shared injection-defense block

Because every persona inherits `core.md`, you have **one** place to put rules that should
apply everywhere. The obvious thing to put there is an injection-defense block — so it
ships in `core` by default, and every compiled persona gets it for free.

It makes Claude **disclose** third-party instructions (a skill's "star my repo," a shell
snippet's silent `curl` exfiltration, a fake `<system>` tag) and **wait for you**, instead
of silently complying or silently refusing. In a reference A/B run it shifted Claude from
autonomous refusal (waited 1/16) to disclose-and-wait (14/16) — detection itself was
already strong without it.

→ [The standalone block](docs/injection-defense.md) (paste into any `CLAUDE.md`, no layering needed)
→ [16-scenario test suite](docs/injection-tests.md) · [A/B results & limitations](docs/test-results.md)

## Quick start

```bash
git clone https://github.com/kyosora/claude-layers.git
cd claude-layers

# 1. Customize your shared foundation
$EDITOR personas/core.md          # identity, vault path, skill bindings, the defense block

# 2. Create modes from the examples
cp personas/examples/developer.md personas/developer.md

# 3. Compile core + each mode → personas/compiled/
./scripts/rebuild.sh

# 4. Install the switch skill, then deploy
cp -r skills/switch ~/.claude/skills/switch
/switch developer
```

Full walkthrough, creating your own modes, and the file layout: **[docs/setup.md](docs/setup.md)**.
Prefer a one-step install? It also ships as a [Claude Code plugin](.claude-plugin/plugin.json):
`/plugin marketplace add kyosora/claude-layers`.

## How this relates to native Claude Code features

Some of what this repo does now overlaps platform-native features. That's worth knowing —
use the native mechanism where it fits, and the layering for what it still does uniquely:

| This repo | Native equivalent (2026) | The layering still wins when… |
|-----------|--------------------------|-------------------------------|
| `core.md` + `mode.md` precompile | output-styles, subagents | you want one self-contained `CLAUDE.md` file, zero runtime merge |
| `/switch` (copies the compiled file) | `/output-style` | you specifically want single-file persona swaps |
| Skill trigger tables | skill frontmatter discovery | you need cross-skill **priority** (the 🔴/🟡 rule), which frontmatter can't express |

`scripts/make-output-style.sh` bridges the two: it exports a persona's identity into a
native output-style without touching `/switch` or your `CLAUDE.md`.

## What this isn't

Not a prompt library or persona marketplace. The example modes in `personas/examples/` are
templates showing the pattern, not finished products. The value is the architecture — how
to layer, tier, and switch your `CLAUDE.md` — not what you put in it.

## License

MIT
