# A8 — Divergence Unpacking

Date: 2026-08-16
Status: In progress. Batch 1 resolved, applied to contracts. Batches 2-5 pending.

## Purpose

The prototype walkthroughs and review round produced a divergence log,
contract defects, and review findings. This document unpacks every item
into a concrete decision: a contract field change, a SKILL.md rule, a
presentation rule, or a test-gap for the A2 experiments. It is the
requirements basis for tickets #7 (Init module) and #8 (brown-field).

## Method

All items are classified by what a change targets:

- **Contract** — a schema field, probe, or principle in the contracts
  document
- **SKILL.md rule** — a behavior the executable skill must implement
- **Presentation rule** — how the skill shows its work to the user
- **Test gap** — something the contracts define but no walkthrough
  exercised; must be tested in an A2 experiment
- **Resolved** — already settled by an earlier ruling (A3/A5/A10) or
  the prototype itself

## Traceability table

| Item | Source | Type | Lands in | Status |
|------|--------|------|----------|--------|
| C1: tooling never probes validation | divergence + defect 1 | Contract | constraints.tool_validation | ✅ Batch 1 |
| B3: volatility is one number | divergence + defect 6 | Contract | volatility pace + note | ✅ Batch 1 |
| C4: transition effective-date boundary | divergence | Contract | key design decisions note | ✅ Batch 1 |
| def2: no single-point-of-failure probe | defect + debrief | Presentation | SKILL.md notice-and-flag rule | ✅ Batch 1 (i4) |
| def4: prior-attempt fog never a question | defect + review | Contract | discovery prior-history probe | ✅ Batch 1 (i5) |
| debrief: the bench (who executes) | debrief + minion-1 | Contract | discovery bench probe | ✅ Batch 1 (i6) |
| A1: answer overflow → probe-and-merge | divergence | SKILL.md rule | interaction protocol | Pending batch 2 |
| A3: stage boundary visible | divergence | SKILL.md rule | interaction protocol | Pending batch 2 |
| B1: discovery depth non-negotiable | divergence | SKILL.md rule | interaction protocol | Pending batch 2 |
| B4: no trim invitation | divergence | SKILL.md rule | interaction protocol | Pending batch 2 |
| B5: adoption failure not surfaced | divergence | SKILL.md rule | interaction protocol | Pending batch 2 |
| C2: expert-user sequence attack missing | divergence | SKILL.md rule | interaction protocol | Pending batch 2 |
| def3: no attribution check | defect + debrief | SKILL.md rule | interaction protocol | Pending batch 2 |
| def5: scale-aware phrasing | defect + debrief | Presentation | presentation rules | Pending batch 3 |
| A4: schema-as-artifact | divergence | Presentation | presentation rules | Pending batch 3 |
| B2: gut-first ordering | divergence | Presentation | presentation rules | Pending batch 3 |
| debrief: trust killers (applause loop, recap deck, choreographed pushback) | debrief | Presentation | presentation rules | Pending batch 3 |
| top5-Q1: stop conditions | review | Test gap / SKILL.md | A2 then SKILL.md | Pending batch 4 |
| top5-Q3: mode detection signals | review | Test gap / SKILL.md | A2 then SKILL.md | Pending batch 4 |
| top5-Q4: known-good thresholds | review | Test gap / SKILL.md | A2 then SKILL.md | Pending batch 4 |
| TG-1: zero contract files written | review | Test gap | A2 persistence test | Pending batch 4 |
| TG-2..5: hostile/disengaged/zero-budget/firing | debrief + review | Test gap | A2 experiments | Pending batch 4 |
| TG-6: silent sections (taxonomy/nav/cross_refs) | review | Test gap | A2 experiment scope | Pending batch 4 |
| A2: known-good default fog | divergence | Resolved | seed v0.1 + A5 (light discovery + fallback shapes) | ✅ Resolved |
| C3: pre-bake domain knowledge | divergence | Resolved | A3 reframe (wayfinder-not-lexicon, authority discovery) | ✅ Resolved |
| rev4: value-pricing never priced | review | Resolved | A10-2 ruling (budget-approval probe, no pricing) | ✅ Resolved |
| top5-Q5: domain knowledge location | review | Resolved | A3 + flow-control/file-architecture principle | ✅ Resolved |
| min1-3: success criteria no field | review | Resolved | A10-1 (success_criteria field applied) | ✅ Resolved |

## Batch 1 — Contract schema changes (resolved 2026-08-16)

Six items, all decided by the user. Applied to the contracts doc.

### 1. Tooling validation probe (C1) — approved with per-tool note

**User ruling:** the skill should know about tooling needing validation
in specific cases (pre-baked gist), probe for it, and record results
with yes/no plus priority flags when regulations require validation.

**Applied:** `constraints` gains `tool_validation`:
```yaml
tool_validation:
  - tool: "platform name"
    validated: unknown | yes | no | n/a
    required: true | false   # do governing requirements demand validation?
    priority: low | medium | high | critical  # flag when no + required
    note: "validation record reference, scope of validation"
```

**Rationale:** an "unvalidated" answer has unbounded outcome (a 3-6
month IQ/OQ/PQ project, not a checklist item). Discovery records the
state; design flags unvalidated+required as potential work-item-zero.

### 2. Volatility multi-speed (B3) — central pace + note

**User ruling:** keep the central `pace`, add notes for everything else.

**Applied:** `volatility.pace` remains the central dominant pace. The
note carries per-layer paces (wine/milk). No new field.

### 3. Transition effective-date boundary (C4) — principle in contracts, mechanism in #8

**User ruling:** technical recommendation accepted.

**Applied:** key design decisions gains the universal principle:
migrations declare a transition effective date; records born after it
are under new controls; distinct from per-document effective dating;
the two must not drift apart ("two dates must be one date"). The
mechanism (sequencing, born-before/born-after handling) belongs to the
brown-field strategy (#8).

### 4. Single-point-of-failure (defect 2) — notice-and-flag, not solve

**User ruling:** the skill should notice when a project takes on high
risk unnecessarily. It does not need to solve it, but it must flag it.

**Applied:** no contract field. A presentation-level rule for the
SKILL.md: when the skill sees a solo-owner project with a single
storage location and cheap redundancy, mention it once as a
professional courtesy, then move on. General principle: notice-and-flag
high risk; do not adopt it as scope.

### 5. Prior-history probe (defect 4) — discovery probe, not triage Q10

**User ruling:** discovery, because triage is already hefty at 9
questions.

**Applied:** Discovery process gains the prior-history probe: "what was
tried before (previous attempts to organize or reorganize), and what
happened?" This operationalizes the Init fog example. Answers inform
design (what not to repeat) and the load-bearing check.

### 6. The bench probe (debrief + minion-1) — discovery question

**User ruling:** discovery, same as #5.

**Applied:** Discovery process gains the bench probe: who actually
executes the work (owns paper binders, walks the floor, does the
handover). Fills `artifacts[].owner` with executors, not titles.

## Pending batches

### Batch 2 — Interaction protocol rules (SKILL.md)

Seven items, all process truths from the prototype:
1. A1: probe-and-merge with a running answer-state map
2. A3: stages are a model, never shown to the user
3. B1: scale table is a ceiling, not a mandate; negotiate depth
4. B4: design presentation MUST invite trimming
5. B5: surface "what survives THIS team?" directly
6. C2: interaction mode detection (cooperative vs exacting-domain)
7. def3: attribution check when the user blames docs

### Batch 3 — Presentation rules (SKILL.md)

Five items: def5 (scale-aware phrasing), A4 (schema is the model,
presentation scales down), B2 (gut-first ordering), debrief trust
killers (no applause loop, no recap deck, no choreographed pushback),
success criteria elicitation.

### Batch 4 — A2 test scope

Four items, the gated SKILL.md questions plus the test gaps:
1. Stop conditions (top5-Q1) — hostile/disengaged/zero-budget/firing
2. Mode detection signals (top5-Q3)
3. Known-good thresholds (top5-Q4)
4. TG-1 persistence test + TG-6 silent sections + TG-2..5 experiments

### Batch 5 — Quick confirms (already-resolved)

Five items, all already settled by earlier rulings. A read-only
confirmation pass.
