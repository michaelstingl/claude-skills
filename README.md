# claude-skills

> A portable collection of [Agent Skills](https://agentskills.io) — each skill is a standard `SKILL.md` directory that works in any skills-compatible agent (Claude Code, Gemini CLI, Cursor, …), with a Claude Code plugin-marketplace manifest layered on top so you can install them individually.

## What this is

Every skill lives under `skills/<name>/SKILL.md` following the open **Agent Skills specification** — so the same files are usable *bare* by any tool that scans for skills, with no Claude-Code lock-in. The `.claude-plugin/marketplace.json` at the root is an **adapter layer**: it exposes each skill as its own installable Claude Code plugin, without duplicating any content (`strict: false` + `skills: ["./skills/<name>"]` points straight at the standard dirs).

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

**Any skills-compatible agent (bare):** copy or symlink a `skills/<name>/` directory into that agent's skills path (e.g. `~/.claude/skills/`). The `SKILL.md` format is the portable standard.

**Claude Code (via marketplace):**

```
/plugin marketplace add michaelstingl/claude-skills
/plugin install wop@claude-skills
```

## Publication gate — every skill is scrubbed before it lands here

Nothing enters this public repo carrying internal references (personal names, private tracking IDs, machine paths). Each skill passes `scripts/scrub-check.sh skills/<name>` first:

```
scripts/scrub-check.sh skills/wop
```

The script's built-in patterns are **generic and structural** (tracking-id shapes, absolute home paths) — they name nobody, so they are safe to publish. Everything project-specific — personal or peer names, your scratch/channel directory names, private repo slugs — lives in a **gitignored `.scrub-deny`** (copy from `.scrub-deny.example`), so the denylist never publishes the very names it hides — the same discipline as a gitignored secret denylist.

## License

Each skill declares its own `license` in its frontmatter where applicable.
