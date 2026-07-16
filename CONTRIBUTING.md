# Contributing a skill

Every skill here is a standard Agent Skill ([agentskills.io](https://agentskills.io)): a directory `skills/<name>/SKILL.md`. To add or change one:

1. **Structure** — `skills/<name>/SKILL.md` (optional `scripts/`, `references/`, `assets/` subdirs). The frontmatter `name` must equal the directory name and be a lowercase slug; `description` is required (what it does *and* when to use it).
2. **English-only** — this is a public repo. No German (or any non-English) anywhere in a skill — SKILL.md, catalogs, examples, *and trigger phrases*.
3. **No internal references** — no personal or peer names, private tracking IDs, machine paths, or context-bound war-stories that only make sense with private context. If an example cites a real incident, generalize it to the principle it illustrates, or cite a public source.
4. **Add a marketplace entry** — one object in `.claude-plugin/marketplace.json` `plugins[]`:
   ```json
   { "name": "<name>", "source": "./", "strict": false, "skills": ["./skills/<name>"], "description": "…" }
   ```
5. **Run the checks locally before you push:**
   ```
   scripts/scrub-check.sh skills/<name>   # internal-reference gate (uses your gitignored .scrub-deny)
   scripts/validate.sh                    # full repo check: structure, spec, English-only, scrub
   ```
   CI runs `scripts/validate.sh` plus a secret scan on every push and PR.

The scrub-check and validate are necessary but **not sufficient**: a structural grep cannot judge whether an example is too context-bound to help an outside reader, and its language check is only a heuristic. Read your skill once as a stranger would — does it stand without your private context? — before publishing.
