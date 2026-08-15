# Assumption Review — big-picture decisions

Date: 2026-08-15
Status: Decisions recorded. A8 (divergence log unpacking) in progress.

## Purpose

The prototype report and the two post-prototype reviews surfaced
assumptions. This document records the user's rulings on each, plus
the contract changes they authorize. It is the decision layer above
`2026-08-15-prototype-walkthroughs.md`.

---

## A1 — Model personas are not valid user research

**Ruling:** Accepted. Persona coverage is estimated at 60-70% of real
user needs. We proceed anyway.

**Consequence:** v1 of the skill is explicitly an iteration, not a
completion. The design must anticipate follow-up rounds driven by real
use. The three-case regression suite remains the anchor for future
testing. Any thresholds or rules tuned on simulated data are treated as
provisional.

## A2 — More tests needed; when and how undecided

**Ruling:** More prototype tests will run. Timing and form are open.

**Consequence:** The gate question from review round 1 (hostile /
zero-budget probe before Init finalization) inherits this deferral.
Nothing is blocked, nothing is promised. Recorded as open work.

## A3 — The skill is a wayfinder, not a lexicon

**Ruling (architecture decision):** The skill does not carry domain
knowledge. It is a wayfinder that specializes in helping a project find
its way to documentation that works. For externally governed domains,
the skill:

1. Identifies the governing documents (regulations, standards,
   guidelines, industry requirements).
2. Locates their authoritative source text.
3. Distills per project what they require of documentation.
4. Pre-bakes only the gist of straightforward, widely-known
   requirements, always marked imperfect.
5. Uses the actual regulation text for serious compliance.

**Consequence:** "Specialized wayfinder" becomes literal: the skill
finds the way to the authorities, then distills. Domain-aware routing
means routing to sources, not routing to pre-baked modules. The
Discovery stage gains authority discovery. Divergence C3 reframes
under this decision.

**Clarification (flow control vs file architecture).** Authority
discovery happens during the Discovery stage. This is flow control
only. Where the logic physically lives (inline in SKILL.md, a
modules/compliance.md file, inside modules/discovery.md) is file
architecture and stays open — the contracts describe WHAT the
procedure does and in what order, never HOW the skill is packaged.

## A4 — Contracts are not stable

**Ruling:** Confirmed. The prototype was the contracts' test, and the
reviews showed why: the state machine never ran, and three design
sections never fired. The contracts stay mutable through at least the
next experiment.

**Consequence:** No schema is frozen. The divergence log keeps producing
contract changes until the persistence test and the failure-mode tests
run.

## A5 — Known-good route: light discovery + fallback shapes

**Ruling:** The known-good route takes a couple of questions, not zero.
Small-scale, low-stakes projects may need several fallback shapes
rather than one default. Example shapes:

- A recipe collection for a visual-UI, Windows user wants a file
  structure that matches how she sees folders.
- A 3D-printed storage organizer project wants a structure that feels
  at home on GitHub (README, build guide, STL links).

**Consequence:** The known-good route runs light discovery (2-4 targeted
probes: delivery medium, user skill level, existing docs). Shape
selection keys on delivery medium and user. The route is not a single
default; it is a family of fallback shapes. If light discovery shows
ambiguity, escalate to full discovery. This matches and extends the
contracts' scale-aware depth for `small`.

## A6 — Dead and load-bearing fields: leave as-is

**Ruling:** No trim or confirmation decisions now. The value or lack of
value of the dead-field candidates and the untested-but-load-bearing
fields plays out over a long time.

**Consequence:** The classification tables in the walkthrough report
stay as reference only. The next experiment is expected to exercise
effectivity, expiry, and first_class cross-references naturally.

## A7 — Hostile probe gates Init finalization

**Ruling:** Deferred to A2. See A2.

## A8 — Divergence log: to be unpacked

**Ruling:** The 13-item divergence log and 6 contract defects need
detailed unpacking into concrete changes. In progress — separate
workstream.

**Consequence:** The unpacking produces, per item, the exact contract
field change, SKILL.md rule, or presentation rule. It is the
requirements basis for tickets #7 and #8.

## A9 — Skills move to their own repository

**Ruling:** The frequently-used skills (documentation for sure, possibly
ste-writing) move into a separate repository, separated from piw, and
work regardless of harness or provider.

**Consequence:** The `documentation` SKILL.md carries no pi-specific
dependencies. The prototype used pi-intercom, but that was the test rig,
not the product. Tool mapping in the skill stays generic (read, write,
search, ask).

## A10 — Success criteria + budget-approval probe

**Ruling:** Both agreed.

1. Add a success-criteria element to the design output: the user's
   success metric, in their words, so the skill can verify later.
2. The existing budget probe (triage Q7, `budget` field) extends to
   probe whether budget approval is a concern, and goes from there.
   No new section; no pricing technique in the contracts.

**Consequence:** Contract changes recorded below.

---

## Contract changes authorized

| Decision | Contract change | Status |
|----------|----------------|--------|
| A3 | Discovery gains authority discovery (governing docs, source text, distillation, gist-with-caveat) | Applied |
| A3 | Design output gains `governing_requirements` (cited) | Applied |
| A5 | Route comment: known_good = light discovery + fallback shapes by medium | Applied |
| A5 | Key design decisions: known-good runs light discovery; fallback shapes | Applied |
| A10 | Design output gains `success_criteria` | Applied |
| A10 | `budget` field gains approval probe | Applied |
| A3/A5 | Fog items updated (known-good seeded; regulatory module resolved) | Applied |

## Open work

1. A8: unpack the divergence log into concrete changes
2. A2: decide when and how the next experiments (hostile, zero-budget,
   persistence-test) run
3. A6: leave fields as-is; revisit after the next experiment
4. Post-v1 iteration loop accepted as part of the project
