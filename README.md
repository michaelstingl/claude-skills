# claude-skills

> A portable collection of [Agent Skills](https://agentskills.io) — each skill is a standard `SKILL.md` directory that works in any skills-compatible agent (Claude Code, Gemini CLI, Cursor, …), with a Claude Code plugin-marketplace manifest layered on top so you can install them individually.

## What this is

Bundled skills live under `skills/<name>/SKILL.md` following the open **Agent Skills specification** — so the same files are usable *bare* by any tool that scans for skills, with no Claude-Code lock-in. The `.claude-plugin/marketplace.json` at the root is an **adapter layer**: it exposes each skill as its own installable Claude Code plugin, without duplicating any content. Bundled skills use relative paths; independently maintained skills use GitHub sources with skill paths relative to that repository.

## Layout

```
claude-skills/
├── skills/
│   └── <name>/SKILL.md        # one standard Agent Skill per directory
├── .claude-plugin/
│   └── marketplace.json       # Claude Code adapter — one plugin entry per skill
├── scripts/
│   └── scrub-check.sh         # publication gate (see below)
└── .scrub-deny.example        # copy to .scrub-deny (gitignored) with your internal names
```

## Use it

**Any skills-compatible agent (bare):** copy or symlink a `skills/<name>/` directory from the skill's repository into that agent's skills path (e.g. `~/.claude/skills/`). The `SKILL.md` format is the portable standard.

**Claude Code (via marketplace):**

```
/plugin marketplace add michaelstingl/claude-skills
/plugin install wop@claude-skills
/plugin install ax@claude-skills
```

### AX has its own repository

AX is maintained in [michaelstingl/ax-skill](https://github.com/michaelstingl/ax-skill), including its catalog, version history, documentation, and CI. This marketplace fetches AX from that repository; the install ID remains `ax@claude-skills`. Existing plugin users can refresh the marketplace and update AX. Bare installations pointing at this repository's former `skills/ax/` directory should instead point at `skills/ax/` in a clone of `ax-skill`.

## Publication gate — every skill is scrubbed before it lands here

Bundled skills must not carry internal references (personal names, private tracking IDs, machine paths). Each bundled skill passes `scripts/scrub-check.sh skills/<name>` first. Remote skills run their publication checks in their own repository; this repository validates their source configuration without fetching or scanning their contents:

```
scripts/scrub-check.sh skills/wop
```

The script's built-in patterns are **generic and structural** (tracking-id shapes, absolute home paths) — they name nobody, so they are safe to publish. Everything project-specific — personal or peer names, your scratch/channel directory names, private repo slugs — lives in a **gitignored `.scrub-deny`** (copy from `.scrub-deny.example`), so the denylist never publishes the very names it hides — the same discipline as a gitignored secret denylist.

## License

Each skill declares its own `license` in its frontmatter where applicable.
