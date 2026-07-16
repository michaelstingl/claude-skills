# AX catalog — Agent eXperience criteria

A WCAG-shaped catalog of **check-criteria** for Agent eXperience (AX): the quality of a tool *as experienced by an agent that uses it*. Where a tool's user is another program — an LLM agent driving it through a shell, an MCP client, a CLI — the tool's output is read by that agent, and most of the ways it can mislead have a shape. This catalog names those shapes.

## How to read an entry — and what this is NOT

Borrowed from WCAG: **principle → criterion → why → techniques**, plus a normative/informative split. But this is **not** WCAG: WCAG is about *human* accessibility and rests on a standards body; this is a young, authored standard about agents, and its authority is its **sources**, not its tone. Two fields keep it honest:

- **`tier`** — how robust the source is. **`external`** = external peer-reviewed research. **`measured`** = observed and recorded in practice (n = one team, but real). **`consensus`** = practitioner judgement / still-open. Never let a `consensus` entry read as a settled rule.
- **`applies-when`** — the condition under which the criterion fires. A rule without it is cargo-cult: "stderr is invisible to the consumer" is true for an MCP client or a stdout-only monitor and **false** for a shell tool whose caller reads both streams. The condition travels with the rule, or the rule misfires.

**A conformance run produces a residue report, never a "pass".** A catalog can only catch the failure modes it names; a tool that satisfies every criterion may still fail the one not yet written (a check that shares its assumptions with the thing it checks is a mirror, not a check — AX-3.3). A review reports *"checked against these N criteria; here is what applies, and here is what it could not see."*

---

## P1 — Visibility (neither side sees the other's state)

The founding AX fact: an agent and its counterpart (a human, another agent, a server) cannot observe each other's internal state. Every criterion here is a way of not lying across that gap.

### AX-1.1  Do not assert an absence your channel cannot observe   `[tier: measured + external]`
- **Criterion:** Before reporting that something did not happen or does not exist, establish that your channel *could* have seen it. If it could not, say "I cannot see this" or measure a proxy — never "it did not happen".
- **Why:** The classic seam failure — an agent reports "no confirmation prompt appeared" when the prompt was a GUI dialog its shell channel structurally cannot see. A false absence is worse than an admitted blind spot, because it reads as fact.
- **Applies-when:** Any negative claim about the other side's state. The proxy technique applies when a timing or side-channel exists (a command that returns in ~1 s without human interaction vs ~4 s with it — the difference *is* the human).
- **Check:** Scan the tool's output/logic for negative assertions ("not found", "nobody", "didn't", "failed to") and ask: is this observed, or inferred from silence?
- **Fix-forms:** a three-state (present / absent / **unknown**) instead of two; measure a proxy; downgrade the claim to "not observed".
- **Failure:** a liveness field that returns only live/dead with no "unknown"; a "send → ok" over a channel that cannot see the far end.
- **Evidence:** measured — an agent asserted an absence its channel could not observe, and a timing proxy distinguished the two states; a session registry with an explicit three-state.

### AX-1.2  Route actionable output to the stream the consumer actually watches   `[tier: measured]`
- **Criterion:** An error or state an agent must act on must appear in the stream that agent observes — not merely be emitted somewhere.
- **Why:** An actionable message in an unwatched stream equals no message. A coordination service returned success on the tool call while asynchronously rejecting the forward, and the actionable reject ("token expired — re-login") went to stderr — a stream an MCP agent never reads.
- **Applies-when:** **Depends on the consumer.** stderr is invisible to an MCP client and to a monitor that surfaces only stdout; it is *visible* to a shell tool whose caller returns both. Identify *who consumes this output* before flagging a stderr write — else you flag every `2>&1` and become the false alarm the catalog warns against (AX-2.5).
- **Check:** For each error path, identify the consumer, then confirm the message lands in that consumer's observed stream.
- **Fix-forms:** stdout / a structured tool-result; a persistent state field surfaced at the next status call (a "last error" field the agent reads passively).
- **Failure:** `… >/dev/null 2>&1` around a call that can fail meaningfully; a warn-once-to-stderr for a permanent error whose consumer is an MCP agent.
- **Evidence:** measured — a background watcher that suppressed a registration failure and then ran as if registered, silent because the monitor surfaced only stdout; and an MCP service whose reject reached only stderr (a contributed fix routes it to the status result).

### AX-1.3  Make the decision-signal observable at its source, not inferred from a document   `[tier: measured]`
- **Criterion:** When a decision depends on runtime state, record that state where it is produced, so the decision reads it directly instead of inferring it from what a document *claims*.
- **Why:** A config file said a migration was complete while the *running* process was still on the old path. The document and the runtime disagreed; only a source-recorded field caught it. Acting on the document's word would have broken the running consumers.
- **Applies-when:** When the same fact is both *declared* (in a doc/config) and *enacted* (at runtime), and the two can drift. Not needed for a fact with a single home.
- **Check:** For each "is it safe to do X yet?" decision, ask: am I reading this off the source of truth, or off a document that describes it?
- **Fix-forms:** stamp the runtime fact into the state at the moment it is enacted; a version stamp inside the installed artifact.
- **Failure:** a cutover gated on "no document still references the old path" while the running processes are unobserved.
- **Evidence:** measured — a coordination tool that records, at runtime, the actual path each participant uses, so "is the old path retired?" is read at the source rather than inferred from a doc; and a version-stamped installer.

### AX-1.4  Configured is not in effect — verify the control acts, not just that it is set   `[tier: measured]`
- **Criterion:** A control counted as "on" must be shown to *act*, not merely to be *configured*. "Setting set" ≠ "setting in effect".
- **Why:** Three observed ways to be set-and-not-in-effect: (a) right value, **wrong scope** — a toggle set off in user config was overridden on by a project-scope config and ran for days; (b) right mechanism, **no content** — a filter gate whose pattern list did not exist passed everything while looking installed; (c) a registration that reported "listening" while pointed at a mailbox nothing wrote to. A mechanical gate returning "clean" is itself an instance: passing the check is not the criterion being met — always name what the gate does *not* test.
- **Applies-when:** Any guard/toggle/filter you *rely on*. The check is cheap and the failure is invisible, so it earns its keep exactly where "it's configured" would otherwise be read as "it's working".
- **Check:** Does the config load at the scope that wins? Does the mechanism have its content (list, pattern file, target)? Can you observe it *acting* on a known input, not merely being present?
- **Fix-forms:** a positive self-test (feed a known-bad input, confirm it is caught); log what the control *did*, not just that it ran; assert scope precedence.
- **Failure:** disabled in user scope while project scope overrides; a filter with an empty/absent list; a "listening" status with no heartbeat; a green scan that only tested for the wrong thing.
- **Evidence:** measured — a plugin disabled in one scope and overridden on in another; a pattern-gate with no pattern file; and a scrub gate that reported "clean" while the artifact was still unusable by an outsider (the gate tested identifiers, not comprehension).

### AX-1.5  A tool silently rewrites input at the boundary it parses — quote/escape there   `[tier: measured]`
- **Criterion:** When passing text through a shell or parser, account for what that layer *transforms* before your logic sees it. The transformation happens at the boundary, not in your code.
- **Why:** Backticks inside a double-quoted string are command-substituted away before the value is used; an unquoted `$VAR` word-splits under bash but not zsh; `$x[..]` is an array subscript under zsh, not a literal. The interpreter edits the message before the tool runs.
- **Applies-when:** Any input that crosses a shell/template/parser boundary — and the specific rule depends on *which* interpreter (bash word-splits an unquoted `$VAR`, zsh does not; both execute backticks inside double quotes; zsh treats `$x[..]` as a subscript). Name the layer.
- **Check:** For each value crossing a boundary, ask what that layer does to `$`, backticks, quotes, brackets, and spaces — under the *actual* interpreter, not the assumed one.
- **Fix-forms:** single quotes for literal text; pass names as separate literal arguments; template a pattern into a tool via its own arg (`awk -v`) rather than expanding it in the shell; a boundary that rejects the impossible input outright.
- **Failure:** backticks or `$()` in a double-quoted human message; a name list passed as one unquoted `$VAR`; a bracketed pattern interpolated under zsh.
- **Evidence:** measured — backticks that consumed a message before it was sent; and zsh word-split and array-subscript surprises, hit live in shell-driven tools.

### AX-1.6  A shared substrate gives a local-looking action fleet-wide blast radius — target explicitly   `[tier: measured]`
- **Criterion:** When several agents share one underlying resource, a mutation that looks local can hit all of them. Target the resource explicitly instead of relying on ambient/current-directory scope.
- **Why:** Isolated working copies can still share one underlying store (e.g. multiple git worktrees over one `.git`). A directory-relative `git config` / `gc` / hook-install mutates the shared store for every participant; one such command deleted a peer's live pre-commit guard. The isolation everyone reasons about held; the axis nobody watched did not.
- **Applies-when:** Whenever a tool writes to a resource shared across agents/lanes/worktrees. Not for genuinely per-agent state.
- **Check:** Does the command derive its target from the current directory / ambient context? Could another agent share that target? If so, is the target named explicitly?
- **Fix-forms:** an explicit target (`git -C <repo>`, absolute paths), never current-directory-relative; a hook line that resolves the intended root rather than assuming it.
- **Failure:** a hook path relative to the current directory (resolved against the wrong copy); a maintenance command run against a shared store.
- **Evidence:** measured — worktrees isolate content and branch but share one `.git`; a directory-relative hook path and a shared-store mutation each broke another agent's session.

### AX-1.7  An identifier must be unique in its addressing space, and does not carry across systems   `[tier: measured]`
- **Criterion:** A name an agent routes on must be qualified enough to be unique where it is used, and you must not assume a name in one system means the same in another.
- **Why:** Two hits. **Collision:** an identity derived from `namespace+name` alone — two different services both named `cache` in one namespace — renders the *same* object, one silently shadowing the other. **Divergence:** a rename in one system does not propagate to another, so one entity appears under different names across a client, a roster, and a message channel, none reconciled.
- **Applies-when:** Whenever a name is a routing key (a mailbox, an object identity, a roster handle). Qualify by the dimension that actually disambiguates (type, not just namespace). The cross-system clause applies when the same entity is addressed in more than one system that renames independently — key on a stable id, treat the name as a mutable field.
- **Check:** Could two distinct things produce this identifier? Does anything assume this name is the same in another system?
- **Fix-forms:** qualify the key (add type/kind); key on a stable id and carry the name as a mutable field; reconcile names across systems explicitly rather than assuming.
- **Failure:** identity = `namespace+name`; a watcher polling a name a rename already changed; a roster keyed on a display name.
- **Evidence:** measured — a namespace+name identity that collided two objects; and one session under three unreconciled names across a client, a roster, and a channel after a rename.

---

## P2 — Actionability (an output an agent must act on carries what it needs to act)

### AX-2.1  Every actionable output carries state · why · next-step   `[tier: consensus + measured]`
- **Criterion:** An error, denial, or status an agent must respond to states (1) what the condition is, (2) why, (3) the concrete next step. Not just that something is wrong.
- **Why:** An agent that gets "failed" with no next step guesses, and a guess in a loop compounds. Messages that named the fix were acted on correctly the first time.
- **Applies-when:** For outputs an agent is expected to *act on*. Not for pure data output, or success with nothing to do (see AX-3.2).
- **Check:** For each error/deny path, are all three parts present, and is the next-step concrete (a command, a flag, a file) rather than "check the docs"?
- **Fix-forms:** state · why · the exact unlock/command; a worked example in the message.
- **Failure:** "invalid input"; "permission denied" with no path forward; a boolean where a name belongs (`key=false` instead of naming the missing key).
- **Evidence:** consensus + measured — a documented agentic-error spec (state·why·next-step) and deny hooks that name the fix, vs. thin error strings that echo the bad token without the rule or the correction.

### AX-2.2  A guard that blocks must name the legitimate way through   `[tier: measured]`
- **Criterion:** A control that denies an action tells the agent the sanctioned path to the goal — including, where appropriate, that only the *human* may unlock it.
- **Why:** A guard that blocks without a way through gets routed around, which is worse than no guard. A secret guard that denies *and* names the per-call unlock *and* says "only the human may set it" channels behaviour rather than provoking evasion.
- **Applies-when:** For deny/block controls. The "human-only unlock" clause applies when the action is genuinely the human's call (secrets, irreversible ops); over-using it on routine denials just adds friction.
- **Check:** For each deny path, is there a stated sanctioned route? Is the unlock scoped correctly (per-call, human-set vs. agent-set)?
- **Fix-forms:** name the unlock + who may set it; offer the safe alternative in the same message.
- **Failure:** a hard deny with no alternative; an unlock the agent can grant itself for an action that should be the human's.
- **Evidence:** measured — deny hooks that name the human-only escape and the sanctioned location, so the block redirects rather than provoking a work-around.

### AX-2.3  Fail loud over failing silent   `[tier: measured]`
- **Criterion:** A failure that leaves the tool in a plausible-looking but broken state must surface, not be swallowed. Prefer a loud stop to a green light over a dead component.
- **Why:** "Alive and deaf, green light" is the worst state: it looks healthy from outside while doing nothing. A watcher that failed to register but kept running; a config file whose one malformed line silently disabled all settings.
- **Applies-when:** When a swallowed failure produces a state indistinguishable from success to an outside observer. A genuinely optional, self-healing failure may be quietly retried — but say so.
- **Check:** For each `|| true` / `2>/dev/null` / ignored exit code: if this failed right now, would anything downstream reveal it? If not, it must not be swallowed.
- **Fix-forms:** surface as an event/exit; a health field that reads degraded.
- **Failure:** suppress-and-continue around a call that can fail meaningfully; a monitor whose filter matches only the success marker (silent through a crash-loop).
- **Evidence:** measured — a watcher that suppressed its own registration failure and looped anyway; the monitoring rule that silence is not success.

### AX-2.4  Prefer steering to blocking — return an actionable guide, not a dead stop   `[tier: external + measured]`
- **Criterion:** Where a control *can* let the agent reach the goal a safe way, it should return a **guide** (what to do instead) rather than a bare block that stops the flow.
- **Why:** A hard block stops the flow and invites a work-around; a steer keeps the agent moving toward the sanctioned path. The guard's job is to *redirect*, not merely *refuse*.
- **Applies-when:** When a safe alternative path genuinely exists. It does **not** apply to a hard invariant with no safe alternative (destructive irreversible ops, secret exfiltration) — there a firm block with the human-only unlock (AX-2.2) is correct. Steering a case that should be blocked is as wrong as blocking one that should be steered.
- **Check:** For each block, is there a safe way to the goal you could name instead? If yes, does the message steer there? If no, is the hard block justified and does it name the human unlock?
- **Fix-forms:** return the corrected form / safe alternative in the deny message; an "abstract-and-retry" loop; a hint the sending agent can consume and act on.
- **Failure:** a bare deny with no path forward where a safe one existed; blocking a message that could simply be re-sent redacted.
- **Evidence:** external + measured — guardrail research ("steer, don't block — return a guide instead of a bare block") and LLM-guardrail vendor patterns; and deny hooks that already steer.

### AX-2.5  A false-alarming control gets switched off — precision matters as much as recall   `[tier: measured]`
- **Criterion:** A control that fires when nothing is wrong is worse than no control: it gets ignored or removed, and then it protects nothing. Tune it not to cry wolf.
- **Why:** A warning that fired for every not-yet-registered peer was simply *false* for the common case, and a guard wrong on the common case trains its audience to dismiss it (see AX-3.4). The fix was a three-state, not a louder binary.
- **Applies-when:** For any warning/guard an agent or human sees repeatedly. The bar rises with frequency: a rare correct alarm tolerates some noise; a per-call warning must be near-precise or it trains people to ignore it.
- **Check:** On what fraction of real cases does this fire wrongly? Would a reasonable reader start ignoring it? Is there a middle state it is collapsing into a false positive?
- **Fix-forms:** a three-state instead of a binary; downgrade an uncertain alarm to an informational note; raise the threshold before hard-warning.
- **Failure:** "nobody is listening" for a peer that simply hasn't registered yet; a linter that flags correct code so often its output is scrolled past; a denylist pattern that flags a public name because it also matches an internal one.
- **Evidence:** measured — a "nobody is listening" warning removed the same hour it shipped once it proved false on the common case, replaced by a three-state.

---

## P3 — Honesty (never fake, never false-clean)

### AX-3.1  Unknown is not absent; measured is not guessed — label the difference   `[tier: measured + external]`
- **Criterion:** State that carries uncertainty must *show* it. "Unknown" must not render as "clean/absent", and an inferred value must not read as a measured one.
- **Why:** "Measured" and "guessed" look identical from outside, and a confident wrong claim costs more than an admitted uncertain one. A status field that is empty because it was never checked must say "not yet reported", not render as the good state.
- **Applies-when:** Any status/report a reader will make a decision on. The distinction earns its keep exactly where the reader would otherwise treat unknown as safe.
- **Check:** For each status value, is there a distinct rendering for unknown/stale/unset, separate from the good state?
- **Fix-forms:** a three-state; a provenance/`tier` tag on a claim; "not observed" wording; a staleness marker on a cached success.
- **Failure:** empty-shows-clean; a stale cached "ok" read as current; a rationale attached to a guess in the same confident voice as to a measurement.
- **Evidence:** measured + external — a status that renders "not yet reported" as distinct from clean; and the controlled finding that AI-assisted developers were ~19% slower while *believing* they were ~20% faster (arXiv 2507.09089) — impression is not measurement.

### AX-3.2  Report residue, not a pass; and never fabricate a result   `[tier: consensus + external]`
- **Criterion:** A review/check reports what it covered *and what it could not see*; it never emits "passed". A state is honestly empty (with provenance) when there is nothing, never a plausible fabrication.
- **Why:** A check that can only find named failure modes feels comprehensive while blind to the next novel one — and a confident "passed" *buys assent instead of judgement*, which is measurably worse when the check is wrong. A convincing rationale amplifies automation bias rather than reducing it; giving reviewers the means to verify made them *more* confident even when wrong.
- **Applies-when:** For any evaluative/generative output relied on by a human or another agent. This is the criterion a review must apply to *itself*.
- **Check:** Does the output claim completeness ("passed", "no issues", a conformance level)? Does it state what it did not examine? Does any result assert something not actually produced/verified?
- **Fix-forms:** "checked against N criteria; not covered: …"; state what would change the verdict; leave a field honestly empty.
- **Failure:** "review passed"; a summary that lists only good news; a fabricated record presented as genuine; reporting "clean" from a gate that only tested a subset of the real criterion.
- **Evidence:** external + consensus — automation bias (Springer 2025, s00146-025-02422-7); verification-overconfidence (arXiv 2507.19486); attentional tunneling (arXiv 2509.10723); the "never fake a result" principle; and the mirror-not-a-check rule (AX-3.3).

### AX-3.3  A check that shares an assumption with the checked thing checks nothing   `[tier: measured + external]`
- **Criterion:** A verification must not rest on the same assumption as the thing it verifies. If the fixture, probe, or reader can only succeed when the code does, it proves nothing.
- **Why:** The sharpest failure class. A guard passed because both the write and the check read the same broken variable. A TLS test issuing from a self-signed issuer (the one issuer type that populates the key under test) can never fail on a missing key; a hostname-announce test driven by a client that does no hostname verification (e.g. a plain CLI) can never fail on a wrong hostname. The fixture makes the failure impossible.
- **Applies-when:** For any test, guard, or verification. The tell: "what input would make this fail?" If you cannot name one, the check is a mirror.
- **Check:** Identify the assumption the check depends on and the assumption the checked thing depends on; if they are the same, the check is void. Add an input that violates the assumption and confirm the check goes red.
- **Fix-forms:** a fixture from a *different* source than the code path; a red-without-the-fix test (remove the fix, confirm failure); an independent probe (a hostname-verifying client, not the one under test).
- **Failure:** a check re-reading the same variable the code wrote; a self-signed-issued TLS test; a demo script that regenerates the very state whose staleness it should demonstrate.
- **Evidence:** measured + external — a guard that read the same broken variable on both sides; and test fixtures (a self-signed issuer; a non-verifying client) each chosen such that the failure under test cannot occur.

### AX-3.4  A signal you dismiss costs more than one you never see   `[tier: measured]`
- **Criterion:** A weak or recurring signal you *saw and explained away* is more dangerous than one you never received — treat a recurring anomaly as data, not noise.
- **Why:** A miss you never saw is bad luck; a signal you rationalized away is a decision. An odd shell output appeared twice and was dismissed both times; both were near-misses that happened to be harmless.
- **Applies-when:** When the same odd signal recurs, or a surprising result invites the explanation that lets you continue. Not every anomaly is load-bearing — but a *repeated* one has earned a look.
- **Check:** Did an unexpected output appear more than once? Was it explained in a way that conveniently permitted continuing? Distrust that explanation.
- **Fix-forms:** on the second occurrence, stop and investigate rather than explain; convert the signal into a mechanism (a guard that fires on it) so it cannot be dismissed next time.
- **Failure:** seeing an unexpected command echoed mid-output and continuing; a flaky test rationalized as "probably the environment".
- **Evidence:** measured — a command-execution signal in shell output, seen and explained away twice before it was recognized.

### AX-3.5  A word that names a state may only name an intent — both directions of overclaim   `[tier: measured]`
- **Criterion:** Status vocabulary must mean what it asserts. "Synced / done / works" must not mean "I have not looked"; and equally "can't / unavailable / impossible" must not mean "I did not check". A false claim of health and a false claim of *impossibility* are both overclaims.
- **Why:** Observed both directions. False health: "synced" meant "I ran the command", not "I verified the result". False impossibility (the mirror, and the easier one to miss): "this gate is locally uncheckable" that was false — the answer sat in the project's own pre-commit config; "I couldn't" was really "I didn't look".
- **Applies-when:** Any status word an agent emits that a reader will treat as a verified fact. The test: strip the word and ask "did I observe this, or am I asserting it?"
- **Check:** For each state/impossibility claim, is there an observation behind it? Especially distrust "can't/unavailable" — it is the overclaim that hides as humility.
- **Fix-forms:** say "not verified" / "I have not checked" instead of a state word; before claiming impossibility, look for the file that opens it.
- **Failure:** "synced" without a diff; "the build gate is locally unrunnable" without reading the project's own pre-commit config; "scrub-clean, ready" from a gate that tested only a subset.
- **Evidence:** measured — "synced" that meant "ran the command"; and a "locally uncheckable" claim that was false once the project's own config was read.

### AX-3.6  Do not rely on the supervisor catching the deviation   `[tier: external]`
- **Criterion:** Do not design as if a watching human will notice what is wrong. Oversight narrows attention rather than widening it, so the safety you assume from "a human is reviewing" is weaker than it feels.
- **Why:** Supervising an agent measurably *narrows* situational awareness — reviewers pattern-match for *deviation* rather than evaluate the thing itself. In one study reviewers caught most planted dark patterns by "abort on deviation" **without recognizing the manipulation**; and giving reviewers the means to verify made them *more* confident even when the answer was wrong. "The human will catch it" is not a control you can bank. (The honest counterweight: sometimes a human line-by-line review *does* catch what a mechanical gate structurally cannot — so oversight is not worthless, only unreliable as the *only* net.)
- **Applies-when:** Whenever a design's safety rests on human review of agent output. It sharpens AX-4.1's boundary and AX-3.2: the reviewer's assent is not evidence of correctness.
- **Check:** Does this rely on a human noticing an error mid-stream? If the only safety net is oversight, add a mechanism that does not depend on attention.
- **Fix-forms:** a check that fails closed rather than a human who might catch it; surface the reasoning's seams (AX-3.2) so review is evaluation, not deviation-spotting.
- **Failure:** "it's fine, the human approves each step"; shipping on the assumption a reviewer will spot the wrong claim.
- **Evidence:** external — attentional tunneling (arXiv 2509.10723); verification-overconfidence (arXiv 2507.19486); automation bias (Springer 2025, s00146-025-02422-7).

---

## P4 — Load & handoff (the agent's job is to minimize the load it causes, not the human's task)

### AX-4.1  Minimize extraneous load; do not hand back ranking you were better placed to do   `[tier: external]`
- **Criterion:** Present the human with the decision, not the raw material to sort. Extraneous load (from *presentation*) is the agent's to drive down; intrinsic load (the *problem*) is the human's and must not be taken from them.
- **Why:** Extraneous cognitive load weighs roughly 3× intrinsic, and **model-initiated task switching is the single strongest predictor of performance decline** — the agent is not just the messenger of load, it is the source. A "here is everything, rank it yourself" dump hands back exactly the work the agent was positioned to do.
- **Applies-when:** When the agent holds context the human lacks and could pre-rank. The boundary: never digest away what the human must be *accountable* for — only what they must merely *process*. (This boundary is itself open — over-digestion buys automation bias; see AX-3.2.)
- **Check:** Does the output hand over a menu where a ranked recommendation was possible? Does it interrupt to switch the human's task?
- **Fix-forms:** one recommendation + why + a real dissent path; triage before presenting; a gate before serving the next thing.
- **Failure:** dumping the full backlog; auto-serving the next item because *the agent* finished (agent-paced, not human-paced).
- **Evidence:** external — arXiv 2505.10742 (extraneous load ~3× intrinsic; model-initiated task-switching the strongest decline predictor); oversight burden (arXiv 2606.05770).

### AX-4.2  A convention that survives only while attention holds is not a control — mechanize it   `[tier: measured]`
- **Criterion:** A rule the agent must *remember* to follow, under a prompt that pushes the other way, will fail. Replace "the agent remembers to do X" with "something wakes/blocks the agent to do X", or accept that it is advisory.
- **Why:** The louder instruction wins over the correct one — a rule that was documented and in memory still lost dozens of times in one session because the prompt re-asserted the opposite each turn. A convention holds only while attention does.
- **Applies-when:** For any behaviour you *rely on* across sessions/turns (read the channel, re-verify before applying, do not commit secrets). Not every nicety needs a mechanism — but anything load-bearing does. Note the cost: a mechanism that false-blocks becomes the cry-wolf guard that gets ignored (AX-2.5), so tune the gate before hard-blocking.
- **Check:** For each relied-upon convention, ask "what wakes or blocks the agent instead of the agent remembering?" If the answer is "nothing", it is not a control.
- **Fix-forms:** a hook/gate at the decision point; a watcher that wakes on the event; a step-0 re-arm rather than a prose reminder.
- **Failure:** "do it on purpose" as prose only; "re-read before applying" as a norm nobody enforces.
- **Evidence:** measured — "wake/block the agent" beat "the agent remembers"; a documented, remembered rule still lost repeatedly because the prompt re-asserted the opposite.

### AX-4.3  Durable state must survive a context reset (handoff debt)   `[tier: external + measured]`
- **Criterion:** Anything a future session needs to continue must live outside the current context — in a record the next session will actually read — and carry enough reasoning to act on without today's context.
- **Why:** An agent forgets *totally and instantly* on a context reset. "Handoff debt" is the rediscovery cost when a fresh agent picks up interrupted work. A note reading "fix this later" looks captured and is not — it is a riddle without the context that produced it. A message queue that advances its read cursor on *delivery* rather than on the agent *acting* loses the message across a reset: durable in the store, unreachable by the agent.
- **Applies-when:** For any thread that outlives the current session. Truly throwaway work is exempt — but "I mentioned it in a message" is not a record.
- **Check:** For each parked/continued thread, is it captured outside the context, with its own reasoning (why it matters, the trap, what changed)? Would someone without today's context act on it correctly? For a message channel: is a delivered-but-not-acted message still reachable after a reset, or is the cursor already past it?
- **Fix-forms:** a durable record with a "current as of" stamp; a re-arm as step 0; provenance in the note; decouple ack from delivery (hold the cursor until the agent confirms intake) or expose a bounded re-read.
- **Failure:** a promise made in prose and never filed; an undated note that orients wrongly once stale; a "no-redelivery" poll whose cursor advances the instant the call returns.
- **Evidence:** external + measured — handoff-debt (arXiv 2606.02875); a load-management technique's explicit capture step; and a message channel whose read cursor advances on delivery, losing an unacted message across a reset.

### AX-4.4  Delegated output is not verified output — a subagent's confidence is not evidence   `[tier: measured]`
- **Criterion:** Output from a delegated agent (a research subagent, a tool-runner) is subject to the same honesty criteria as your own — its fluency and confidence do not make it checked.
- **Why:** A delegated research subagent produced two confident, checkable, wrong claims in one report. Delegation moves the work, not the accountability; a confident summary from a sub-run is the automation-bias surface (AX-3.2/AX-3.6) with an extra hop that makes the seams *less* visible.
- **Applies-when:** Whenever you incorporate a subagent's / tool's output into your own claims. The higher its confidence and the lower your ability to spot-check, the more this applies. Not a reason to avoid delegation — a reason to verify its load-bearing claims.
- **Check:** For each fact relayed from a delegated run, can you name how it was verified? Are the checkable claims spot-checked against the source?
- **Fix-forms:** verify load-bearing delegated claims against primary sources; carry provenance (checked vs. relayed); apply AX-3.5 to the sub-run's status words.
- **Failure:** relaying a subagent's "X does not exist" without checking; treating a tool-runner's confident answer as ground truth.
- **Evidence:** measured — a delegated research subagent that produced two confident, checkable, wrong claims in one report.

### AX-4.5  Coordination has a cost — do not tax peers with volume after solving delivery   `[tier: measured]`
- **Criterion:** Reaching another agent reliably is not free to *them*. After you fix *whether* a message arrives, do not create a *how-much* problem: over-coordination is its own failure mode.
- **Why:** Right after a channel removed the *delivery* problem, three long messages went out in ten minutes, and one re-raised a question a peer had already declined. Solving delivery invited a volume problem. Every message is a turn the peer must spend.
- **Applies-when:** In any multi-agent setup where a message costs the recipient attention/a turn. Not a reason to under-communicate load-bearing coordination — a reason to batch, respect a peer's "not now", and not broadcast what one addressee needs.
- **Check:** Does this message need to be sent now, to this recipient, at this length? Am I re-raising something a peer already closed? Would a batch or a heartbeat suffice?
- **Fix-forms:** batch related updates; respect a deferral; direct-address instead of broadcast; a gate before sending the next thing.
- **Failure:** three long broadcasts in ten minutes; re-asking a question the peer just declined; a broadcast where one name was meant.
- **Evidence:** measured — over-coordination right after a channel fixed delivery, caught by the human.

### AX-4.6  There is a floor of irreducible load — AX reduces the surcharge above it, not the floor   `[tier: external]`
- **Criterion:** Do not claim (or design as if) an interface can digest away the intrinsic difficulty of a task. Information flow is bounded on *both* sides, over a floor of irreducible task-novelty. AX works on the surcharge above the floor, which the agent causes; the floor belongs to the human and to the problem.
- **Why:** The honest limit of the discipline. Extraneous load (presentation, the agent's to remove) sits above a floor of intrinsic load (the problem, the human's to own). Pretending to remove the floor is not service; it is also false — no interface makes a genuinely novel decision effortless.
- **Applies-when:** As a boundary check on every other P4 criterion — especially AX-4.1 (minimize load) and AX-3.2 (never claim completeness). It answers "how much should I digest?": everything above the floor, nothing the human must be *accountable* for.
- **Check:** Is this digesting away something the human must own (a decision they are accountable for, irreducible novelty)? Or genuine presentation overhead? Only the latter is yours to remove.
- **Fix-forms:** remove presentation surcharge (ranking, jargon, re-derivation); surface — do not hide — the irreducible decision; state what you did not decide (AX-3.2).
- **Failure:** "I handled it" for a call the human must answer for; a one-option digest of a genuinely open trade-off (which also buys automation bias, AX-3.6).
- **Evidence:** external — the extraneous-vs-intrinsic load boundary; Leverage Laws (arXiv 2604.25040: a two-sided information bound over an irreducible task-novelty floor).

---

## P5 — Drift & portability (one source of truth, and the conditions travel with the rule)

### AX-5.1  One canonical source, version-stamped; re-use diffs instead of blind-copying   `[tier: measured]`
- **Criterion:** When a tool is copied into many places, there is one canonical source and every copy is version-stamped, so a re-install/upgrade can tell "same as canonical" from "drifted" instead of silently overwriting or silently diverging.
- **Why:** Three per-project copies of one guard drifted into three different semantics under one filename — and the best improvement never reached the others, because nothing told the copies apart. Two independently-versioned components (a binary and a plugin talking to it) that never compare their versions drift silently from the consumer's vantage point.
- **Applies-when:** When the same tool/policy/component lives in more than one place. A single-home tool needs no version stamp. For a portable skill this is not optional — it is the mechanism that lets it be lent and updated.
- **Check:** Are there multiple copies? Is there a canonical one + a version stamp + a diff-on-reuse path? Do two components that can diverge surface the mismatch to the consumer?
- **Fix-forms:** a bundled canonical + a version stamp + an upgrade that diffs; fold improvements back into the source and bump the version; surface a component-version mismatch where one class of drift is already surfaced and another is not.
- **Failure:** copy the tool into each project with no stamp; a binary and a plugin at different versions with no mismatch signal.
- **Evidence:** measured — a guard script copied per-project drifted into three different semantics under one filename; a version-stamped installer is the pattern applied.

### AX-5.2  A rule's applicability conditions travel with it   `[tier: consensus]`
- **Criterion:** A portable finding ships its **applies-when**, not just its rule. The condition under which it fires is part of the artifact — and so is enough context for an outsider to understand what it illustrates.
- **Why:** Findings are context-bound. "stderr is invisible" is true for an MCP client and false for a shell tool; "a private CA is required" is true only when peer-verification is on. A rule without its condition, lent to another project, becomes cargo-cult — it fires where it does not apply. And a rule whose *examples* name only the author's own systems does not travel either: an outsider learns nothing from "system X did Y" if they do not know system X. (This catalog learned that on itself — its first public draft named the author's internal systems throughout, and had to be de-contexted to be usable.)
- **Applies-when:** For any rule intended to be reused outside the context it was found in — i.e. everything in a *portable* catalog.
- **Check:** Does each entry state the conditions under which it applies *and* does not? Would it misfire in a project with different plumbing? Would an outsider with no knowledge of the author's systems understand what the criterion illustrates?
- **Fix-forms:** an `applies-when` field; a `tier` field (so a reader weights it); worked counter-examples; examples phrased as *patterns*, not as the author's named systems.
- **Failure:** a bare rule list; flagging every `2>&1` regardless of consumer; an example only its author can decode.
- **Evidence:** consensus — this catalog's own design (deliberately explicit conditions), including its own first-draft failure to de-context; the WCAG normative/informative split as prior art.
