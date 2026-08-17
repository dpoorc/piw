# #7 — Init Module Design (Stage 0)

Date: 2026-08-17
Status: Design draft — reviewable
Basis: contracts (triage schema, Option D), batch-4 stop conditions,
B9 known-good state, A2 operational learnings.

## Purpose

Init is the entry point of the `documentation` skill: what happens the
first time the skill runs in a project. It is conversation-based, not
form-based. It produces a state record and a route — and it does both
through a natural conversation that respects the moment of commitment
(A2: in-session delivery is the default).

## Design principles (carried from decisions)

1. **Init is a conversation, not a form.** The triage schema is a
   structured summary OF the conversation, never a questionnaire to
   fill out. The skill interprets answers conversationally.
2. **Route first, then depth.** Init determines the route
   (known_good | full_cycle | extended) before deciding how deep the
   work gets. The route determines what Init produces and what
   Discovery reads.
3. **Stop conditions apply inside Init.** The save-and-exit protocol
   (batch 4) starts here — the earliest moment a hostile or disengaged
   user is met. Init must never feel like an interrogation the user
   is trapped in.
4. **Statefulness is minimal and honest.** Init writes exactly what
   the route needs. Known-good writes one minimal record (B9); full
   cycles write the triage contract. Nothing more.
5. **The easy-out is always in the room.** Every Init interaction
   offers a low-friction exit ("if there's nothing, say so and I'll
   leave you alone" — A2 Lena). This is not a trick: it is how the
   skill distinguishes engaged from disengaged without force.
6. **Green-field and brown-field fork early but share the probe
   core.** The fork happens at the description probe; the shared core
   (audience, maintenance, volatility, budget) applies to both.

## Input

- No prior skill state (fresh project).
- One user input: the project, described however they describe it.
- Optionally: an existing `docs/meta/` directory (re-run, or migration
  continuation — see re-run section).

## Process — the Init conversation

### Phase 0.0 — Open

The skill introduces itself in one or two lines: what it does
(documentation structure that fits the project), its wayfinder stance
(no pre-baked domain knowledge), and the commitment level (the
conversation is short; the deliverable is small). No process language,
no jargon.

Then the first, single probe — the open door:

> "Describe the project in your own words"

This is the *only* mandatory probe. Everything else flows from it.

### Phase 0.1 — Route detection (fuses with the open)

Route detection is **concurrent with interpretation**, not a separate
step. As the user describes the project, the skill listens for:

**Fast-forward triggers** (route straight to full/extended):
"regulatory," "audit," "QMS," "compliance," "we have a wiki/
Confluence," "500 pages," "legacy," "enterprise," "team of N."
Each trigger is a heuristic, applied with judgment — a research lab
saying "we need FDA compliance docs" routes extended; a hobbyist
saying "I keep a wiki for my recipes" does not.

**Small/known-good signals:** tiny team, personal project, hobby,
no regulatory mention, no existing doc burden.

**Fork detection:** "we already have docs" / "there's years of
history" → brown-field path (see Phase 0.4).

Route decisions:
- Fast-forward trigger → **extended** (skip light probes, run full
  discovery)
- No triggers + small signals → **known_good** (light probes, 2-4)
- Everything else → **full_cycle** (standard discovery depth)

The route is tentative — event-driven escalation (collision,
ambiguity, complexity revealed) can upgrade it later (Option D).

### Phase 0.2 — Light probes (known_good route only)

When route = known_good, run 2-4 targeted probes — NOT the full
triage battery:

1. Delivery medium: "Where do people actually get this info —
   somewhere on a screen, or physical (paper, cards, floor)?"  (B8:
   the question surface matters.)
2. User skill level: "How comfortable are you with markdown/files/
   git?" (shapes the fallback variant).
3. Existing docs: "Is there anything already written down, even a
   folder of notes?" (A2 Dan: "prior history" probe, lightly).
4. The one probe the user's answer makes necessary (they raised a
   pain point → probe it directly).

Then: **shape selection** from the fallback variants keyed on
delivery medium + skill level (A2 Tomás: markdown in repo for a
maintainer; Lena: physical card reference for a property owner).
If light discovery surfaces ambiguity or a collision in the story,
**escalate to full_cycle** (Option D).

Then: deliver the small thing in-session (Phase 0.5), write the
known-good state record.

### Phase 0.3 — Full probes (full_cycle / extended routes)

When route = full_cycle or extended, run the full triage battery —
the 9 probes, conversationally, free-form:

1. Project description (from the open — already have it, confirm).
2. Existing documentation? How much, in what form?
3. Domain (ambient context — free-form, not categorical).
4. Who reads it? How far apart are their backgrounds?
   (cognitive distance — NOT audience count)
5. How many people? How many on docs? (maintenance pattern)
6. Regulatory or compliance? (routes extended, authority discovery)
7. Timeline and budget? (and: budget-approval concern — is there a
   decision-maker who must approve scope/spend? — A10)
8. Relationship with docs? (core / necessary / afterthought / hostile)
9. Volatility? (stable / slow / moderate / fast / chaotic; wine &
   milk note)

Probing rules (from batch 4 + learnings):

- **Probe-and-merge:** interpret each answer as you go, merge into a
  growing understanding, don't store raw Q&A.
- **Answer-state map:** track what's known, what's fog, what's
  contradictory. Collision (contradictory facts, unstable answers) →
  **escalate** (the story may not fit the simple shape).
- **Fog fallback:** an unanswered or unanswerable probe is recorded
  as fog with a conservative default, and the conversation continues
  (A2 Run 1 live-validated: silent client → fog + continue; client
  returned later → updated).
- **One probe at a time** — never batch questions. Each probe is a
  single, human-scaled ask, with the easy-out present.
- **Attribution check on pain claims** (batch 2): if the user says
  "documentation never works here," dig one level: what specifically
  failed before? (Marta: "compliance theater"; Dan: "unverified.")
  — this is probing, not psychotherapy.

**Authority discovery trigger:** if regulatory/compliance surfaced
(probe 3 or 6), Init flags it — the full authority discovery runs in
Discovery (Stage 1), not Init. Init only records the flag.

### Phase 0.4 — Brown-field fork

When "docs already exist" (probe 2, or the open):

- Record `brownfield.exists: true | partial` + volume estimate
  (light → catastrophic) + format.
- **Do NOT run brown-field survey in Init.** Inventory, assessment,
  migration planning belong to the brown-field strategy (#8). Init's
  job is to record existence and volume — the discovery stage decides
  depth.
- **Transition effective date principle** (batch 1): the migration's
  effective date is named later, in the strategy; Init never sets it.
- Prior-history probe (Marta): "has this been tried before? what
  happened?" — cheap, high-value, belongs in Init. If yes → note in
  the triage record.

### Phase 0.5 — Delivery model

- **known_good:** deliver the small thing NOW, in-session (A2: same-
  turn delivery). The deliverable — a one-page, medium-shaped artifact
  from the fallback variants — IS the output. The state record is
  minimal (B9).
- **full_cycle / extended:** do NOT deliver a structure in Init.
  Produce the triage record, then transition to Discovery in the same
  session if the user is present and engaged (continuity, momentum).
  If the session ends after Init, the triage record is the resume
  point (TG-1 persistence: the file carries state across sessions).

### Phase 0.6 — Stop conditions (apply throughout, but the doors)

Track three states during Init:

- **Engaged:** answering richly, volunteering context, pushing back
  productively → continue.
- **Hostile** (angry, aggressive, dismissive of the work itself):
  → **save and exit immediately.** No re-engagement attempt. Write
  whatever was learned (even a sentence) as the partial record.
- **Disengaged** (passive, low energy, one-word answers, deflecting):
  → ONE re-engagement offer via a concrete mode option (batch 2 #6),
  then save and exit if it fails. Never interrogate a disengaged
  user.
- **Zero-budget is a CONSTRAINT, not a stop** (A10). It changes the
  shape options, never ends the conversation.

Exit states write: minimal partial state — partial triage or a
one-line known-good note. A run that stops early still leaves a
resume point.

## Outputs

### known_good route

`docs/meta/known-good.md`:

```yaml
date: "YYYY-MM-DD"
route: known_good
deliverable: "path to the artifact (or description if not a file)"
condition: "the client's stated test, verbatim if given (B5)"
medium: "the delivery medium / shape variant used"
note: "free-form — what was delivered, next step if engaged"
```

### full_cycle / extended routes

`docs/meta/triage.md` — the full triage contract (schema in
contracts doc, Stage 0 section). Sections: description, scale,
route, brownfield, audiences, maintenance, regulatory, budget,
culture, volatility, fog, notes.

### Re-run semantics

If `docs/meta/` already exists:

- **Same project, continuation:** the skill reads the existing
  triage.md (or known-good.md) and resumes — it does NOT re-ask
  settled answers (persistence validated in A2 Run 1).
- **Same project, re-init:** the user says "start over" → the skill
  archives the old record (moves to `docs/meta/archive/` or similar)
  and starts fresh. It asks about the old record's fate first
  (respect the stateful core; retirement never means deletion).
- **Different project:** impossible to confuse — the description
  probe disambiguates within one turn.

## Meta-component discovery

Init scans the project for existing conventions and structures that
constrain documentation:

- Existing `.github/`, `CONTRIBUTING.md`, `README.md` patterns
- Existing skill/config files (e.g., `.pi/agent/`, skills dirs) —
  conventions the docs must fit
- Existing `docs/` with prior structure
- Existing templates (issue forms, PR templates) — the question
  surface (B8)
- Regulatory/config files hinting at governance (compliance dirs)

This is a **scan, not a survey**: Init records what it finds and
whether it constrains the structure. It does not analyze depth — that
belongs to Discovery. The scan is cheap (read-only), and its output
feeds the triage record's brownfield/audience sections and the
delivery/medium decision (B8: the question surface is a pointer
location).

## Scale detection

Scale (`small | medium | large`) is derived, not asked: the skill
estimates from people count, doc burden, and team structure mentioned
in the conversation. It is never probed directly ("how big is your
project?" is a bad probe — vague, self-serving). Derivation signals:

- Small: 1-5 people, no dedicated doc role, personal/hobby or tiny
  team, no compliance (→ likely known_good)
- Medium: 6-50 people, partial doc roles, structured but not
  regulated (→ full_cycle)
- Large: 50+ people, dedicated doc org, complex structure, likely
  compliance/governance (→ extended)

Scale is a *prior* — the route (with fast-forward triggers) decides
the actual path. A 200-person engineering org with no docs at all
and no compliance is still full_cycle, not extended.

## Interaction rules that Init must honor

(From batch 3 presentation + batch 2 interaction + A2 findings.)

- **Gut-first ordering:** lead with the user's own words and pain,
  not a framework. Structure comes later.
- **Scale-aware phrasing:** human-scale language matches the project
  size. No "governance tenets" to a hobbyist.
- **Schema-as-model:** show the triage record as a model (a few
  bullets the user can see themselves in), not raw YAML — unless the
  user asks for raw.
- **No trust killers:** no applause-loop callbacks, no recap-deck
  closings, no choreographed pushback invitations. Subtle natural
  pushback invites ("does this plan look right?") are fine — once.
- **Option-offering with consent** (batch 2): offer modes framed by
  what's known; the user chooses; re-offer if engagement shifts.
- **In-session delivery default** (B6): begin the work in the same
  session as the agreement. Deferral, if offered, is agent
  discretion.
- **Build the client's stated test into the artifact** (B5): if the
  user gives a condition/test during Init, it appears in the
  deliverable or record, structurally.
- **Silence on the closing beat** (B7): when the user departs, the
  exchange ends. No follow-up nudge.

## What Init does NOT do

- Does NOT run authority discovery (Stage 1).
- Does NOT run brown-field inventory (Stage 1 / #8).
- Does NOT design the structure (Stage 2).
- Does NOT probe scale directly (derived).
- Does NOT batch probes (one at a time).
- Does NOT interrogate a disengaged user (stop, then exit).
- Does NOT chase a hostile user (save, exit).

## Accept/reject criteria

A good Init run:

1. Determined the correct route (known_good | full_cycle | extended)
   conversationally, without form-filling.
2. Wrote the correct minimal state (known-good.md OR triage.md).
3. Handled fog honestly (recorded + conservative default, continued).
4. Respected stop conditions (no interrogation, clean exits).
5. Scanned meta-components cheaply and used them.
6. Seeded the next stage cleanly (continuity or clean resume point).
7. Left the user feeling the easy-out was real (engagement was
   voluntary, not coerced).

## Open items (flagged, not resolved)

- Exact fallback shape variants by medium (A5) — still WIP, seeded
  v0.1; the writing phase refines against this design.
- Whether Init probes the question surface (B8) explicitly or rely
  on the meta-component scan to find it. (Lean: scan finds it;
  probe only if scan is empty.)
- Re-run semantics detail: archive naming, "same project" detection
  edge cases.
- The exact delivery-shape selection table (known-good medium × skill
  level → variant) — belongs in the writing phase with fallback
  shapes.

## Standing requirements for the final skill product (user, 2026-08-17)

1. **Cryptic reference removal.** The final SKILL.md and its support
   files must not carry internal decision-tracking references
   ("batch 2", "A4", "B5", "Option D", "TG-1", etc.). They are fine
   in research docs (contracts, unpacking, this design) as audit
   trail, but the skill product stands alone: every rule is
   expressed in plain language, self-justified, or cites the source
   only as a clean reference if needed.
2. **Bias-neutrality review pass.** The skill content shows a bias
   toward the latest-explored topics (A2 vocabulary, recent rulings)
   at the expense of earlier work. A dedicated review round — or
   rounds — is required before shipping to restore neutrality:
   weigh all research (earlier + later) equally, and treat every
   decision as a hypothesis, not a settled fact. The A1 post-v1
   iteration loop is the safety net, but the review pass is
   expected to happen before first release.
