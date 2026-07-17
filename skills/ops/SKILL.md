---
name: ops
description: Use when responding to a cluster/ops incident — a node or pod stuck, an alert firing, a control-plane, etcd, storage, or DNS problem — BEFORE improvising, reaching for memory, or running any destructive remediation. It routes you to the project's runbooks first and enforces triage-before-mitigate.
---

# ops — runbook-first incident response

An incident is where an agent is most tempted to improvise from memory, and where improvising is most expensive. The failure this skill exists to prevent is concrete and observed: an agent hit a control-plane flake mid-operation, went to its own notes for the fix, and ran the exact destructive remediation (`delete + recreate`) that the in-repo runbook **explicitly warns against** — because the reflex to open the runbook first never fired. The docs existed, were complete, and were correct. What was missing was the discipline to reach for them at the moment of the task. That is what a skill is for.

## The rule

**On any cluster/ops symptom, consult the project's runbooks BEFORE acting.** Not after a first guess, not after "just trying one thing" — first. A runbook you read after the destructive step is a post-mortem, not a runbook.

## Three beats, in order

### 1. Runbooks-first — route before you reason

- Enumerate the project's runbook directory (see *The descriptor* below) and match the **symptom** to a runbook. Read the matched one properly — its Trigger/Symptom section confirms the match, its "Do NOT" lines are load-bearing.
- Only if **no** runbook matches do you fall back to a kit, prior investigation, or first-principles debugging — and say that no runbook covered it (that gap is itself a finding: the next step is to write the runbook).
- Do not skim. A runbook read halfway produces a session that *believes* it knows the fix — worse than one that knows it must look.

### 2. Triage before mitigate

- Runbooks split into **Triage** (read-only — an agent may run all of it) and **Mitigate** (approval-gated — often destructive, often human-run). Run the triage, **confirm the diagnosis with its evidence**, and only then reach for mitigation.
- **Never run destructive remediation before the runbook is consulted.** Deleting/recreating a node, wiping a volume, force-removing a finalizer — these are the actions a runbook most often gates or forbids, because the naive version re-triggers the very trap (recycled resources inheriting poisoned state, quorum loss, cascading deletes).
- If a mitigation is blocked by a permission gate or a safety classifier, that is the guardrail working — **hand it to the human, do not engineer around it.** The runbook likely already says "a human runs this."

### 3. Validate the runbook's own success signal

- Check the signal the runbook names — a metric back to N, a member Ready, a value readable — **not pod status.** A retry-loop pod stays `Running` while permanently broken; "the object exists" is not "it works." The runbook tells you what to actually confirm.

## The descriptor — where a project's runbooks live

This skill is the **mechanism**; each project owns its **content**. Read the project's runbook location from its ops entry point — conventionally `ops/runbooks/` in the project repo, with a `README`/index that maps symptom → runbook. If the project has no runbook index, enumerate the directory and match on each runbook's `title` / Trigger section. If a project has no runbooks at all, say so and fall back to careful first-principles debugging — and propose capturing the fix as the project's first runbook.

Keeping the routing in the project (not hard-coded here) is what keeps this skill correct across projects and true when a project's runbooks change — the same split `/seed` uses for orientation.

## What this skill must never do

- Never run a destructive mitigation before the matching runbook has been read.
- Never work around a permission/classifier block on a destructive op — surface it to the human.
- Never report success from pod/object status alone — confirm the runbook's stated signal.
- Never treat prior notes or memory as a substitute for the current runbook — runbooks are versioned and the incident in front of you may differ from the one you remember.

## Why it is built this way (do not "simplify" these back)

- **Runbooks-first is a routing decision, not a knowledge one.** The agent usually *can* reason its way to a fix; the point is that the runbook encodes the traps reasoning misses (the recycled-resource poison, the day-2-doesn't-work rule, the "this looks transient but is permanent" costume). Reaching for it first is cheaper than re-deriving — and it is the difference between the documented fix and the anti-pattern it warns against.
- **Triage is agent-safe; mitigation is gated on purpose.** Read-only diagnosis is exactly what an agent should do first-line (this is the HolmesGPT-lite shape: read-only access + runbooks + an investigation loop). The destructive half stays human-approved because recovery from a wrong destructive step is the worst-case, and a classifier/permission gate is the last line before it.
- **Validating the named signal, not pod status, is the one that catches silent failure.** The most dangerous incidents wear a healthy costume — a sealed store behind a retry loop, a lost TSDB that looks like a young one. The runbook names the signal that pierces the costume; trust that, not the green checkmark.
