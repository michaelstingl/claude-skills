---
name: ax
description: >
  Review a tool for Agent eXperience — its quality as experienced by an agent that uses it —
  against a source-backed catalog of criteria (visibility, actionability, honesty, load,
  drift). Produces a residue report (what applies + what it could not see), never a "pass",
  and proposes fixes rather than applying them. Use on a script, CLI, hook, error path, skill,
  or config. Trigger phrases: "/ax", "AX review", "review the agent experience of", "check
  this tool's AX", "is this agent-friendly", "review this hook/script for agents".
---

# ax — Agent eXperience review

Review an artifact against the bundled catalog `catalog/AX-CATALOG.md` (26 criteria, 5 principles), each with a verified source. The catalog is the expertise; this skill applies it. **Read the catalog at the start of every run** — it is the source of truth, not your memory of it.

## What this is, and the two rules that define it

- **A residue report, never a pass.** A catalog only catches the failure modes it names; a check that shares its assumptions with the checked thing is a mirror (see AX-3.3). So you report *"checked against these criteria; here is what applies, and here is what I could not see"* — you never certify a tool as AX-clean. This is the one criterion `/ax` applies to itself (AX-3.2, AX-3.6).
- **Propose, do not apply.** Suggest fix-forms; the author decides and edits. Unsupervised auto-rewriting is the wrong end of the automation curve (AX-4.6, and the Ironies of Automation).

## How to run it

1. **Read `catalog/AX-CATALOG.md`.** Note the `tier` and `applies-when` fields — they are load-bearing.
2. **Identify the artifact and its consumer.** A criterion's applicability depends on *who reads the output* and *what parses the input* (an MCP tool vs the Bash tool vs a human; bash vs zsh). Establish this first — most false findings come from ignoring `applies-when`.
3. **Walk the criteria.** For each, decide: does its `applies-when` hold for this artifact? If not, skip it (and record that you skipped it). If yes, look for the failure pattern; if found, record a finding.
4. **Apply `applies-when` honestly — do not flag what does not apply.** Flagging every `2>&1` regardless of consumer is exactly the false-alarm the catalog warns against (AX-2.5). A finding you cannot tie to a real consequence is noise.
5. **Emit the residue report** (format below). Rank real findings first; be explicit about coverage gaps.

## Output format

```
## AX review — <artifact>   (catalog vN, M criteria)

Consumer(s): <who reads this output / what parses this input>   ← decides applicability

### Findings
- [AX-x.y] <criterion title>   · <file:line>   · tier:<t>
  - what:  <the specific instance here>
  - why it applies: <the applies-when condition that holds>
  - fix-form: <a suggested technique from the catalog — proposed, not applied>
  - evidence: <the catalog's source for this criterion>
- …ranked, most-consequential first…

### Checked but clean / not applicable
- [AX-x.y] skipped — applies-when not met (<why>)
- …so the reader sees the criterion was considered, not missed…

### What this review could NOT see  (the residue — read this part)
- <criteria that need runtime/consumer info you did not have>
- <artifact surfaces out of scope (e.g. prose vs script)>
- <the structural blind spot: this is 26 named failure modes; a novel one is invisible here>

### This is not a pass
<M criteria checked against, not a clean bill.> What would change the verdict: <e.g. confirming the consumer, running the tool, a criterion not yet in the catalog>.
```

## Scope — what to review

Tools, scripts, hooks, CLIs, error/deny paths, config, and skills. For **prose-only** skills, the load/handoff principle (P4) and honesty (P3) apply to the *output shape*; the visibility/actionability tool-criteria (P1/P2) mostly do not — say which lens you used. When unsure whether a criterion fits the artifact type, that uncertainty goes in the residue, not into a forced finding.

## Calibrating depth

Match effort to the ask. "quick AX look" → the highest-tier, most-applicable few criteria + the residue. "thorough AX review" → all 26, with the not-applicable list shown so coverage is legible. Never pad findings to look thorough — an invented finding trains the reader to dismiss the real ones (AX-2.5, AX-3.4).

## The catalog is versioned and bundled

`catalog/VERSION` + `catalog/AX-CATALOG.md` travel with this skill, so it is portable — lend the skill, the expertise comes along (AX-5.1). Each criterion carries a `tier` (external / measured / consensus): weight a `consensus` finding lightly, an `external` one heavily, and a `measured` one as a real-but-single-source pattern. When you improve a criterion, fold it back into the catalog and bump `VERSION` — do not let a local edit drift (AX-5.1).

## What /ax must never do

- Never output "passes AX" / "AX-compliant" / a conformance level. Residue only.
- Never auto-edit the artifact. Propose.
- Never flag a criterion whose `applies-when` does not hold to inflate the report.
- Never present a `consensus`-tier or unverified claim in the same confident voice as a `measured`/`external` one.
