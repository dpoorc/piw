---
id: 6
title: 'Grilling: Structure discovery procedure'
status: in-progress
priority: high
labels:
    - wayfinder:grilling
    - docs
relations:
    blocks:
        - 7
        - 8
    depends-on:
        - 2
created: "2026-08-08"
updated: "2026-08-11"
---

## Question

What is the procedure to arrive at a good documentation structure for any project?

## Progress

Procedure skeleton designed through grilling session (2026-08-09):

- **Phase 0 — Triage:** 6 free-form questions (describe project, docs
  exist?, domain, audiences, maintenance capacity, regulatory). Routes
  to branch (small/simple → known-good default, medium → full cycle,
  large → extended with compliance).
- **Phase 1 — Discovery:** Maps audiences, needs, existing artifacts,
  constraints, failure modes → requirements map stored in docs/meta/.
- **Phase 2 — Design:** Translates requirements to structure,
  taxonomy, navigation paths, lifecycle model, load-bearing check.
- **Key decisions:** Init includes triage, discovery is separate module
  (Option C). Stateful via docs/meta/ with pause/resume. Brown-field
  flag with phased approach. Parallel work via issue tracker.
  Omission ladder: high-churn → ruthless; stable → document freely.
  Known-good default for small projects remains fog.

See [research/2026-08-09-structure-discovery-procedure.md](docs/research/2026-08-09-structure-discovery-procedure.md).

### Progress this session (2026-08-11)

**Full stage contracts document written** (604 lines):

See [research/2026-08-10-contracts-discovery-procedure.md](docs/research/2026-08-10-contracts-discovery-procedure.md)

**Init (triage):** 9 questions defined covering:
- Project description, docs status, domain (free-form),
  audience groups + cognitive distance + notes,
  existing artifacts/inventory, maintenance model + patterns (11 patterns),
  budget + timeline, documentation culture (core→hostile),
  churn/volatility (stable→churn)

**Discovery:** Multi-axis audience model, scale-aware branching,
  fog + conservative default for unknowns, constraints as structured
  fields (regulatory, versioning, distribution, language/i18n,
  accessibility, tooling).

**Design:** Authoring/retrieval separation (organization model),
  6 arrangement types, taxonomy type (4 types), lifecycle model
  (state machine + alternatives), template governance tiers (0-3),
  cross-references (3 models), verification tables connecting stages.

**Research sources integrated:**
- Industry practices (military, libraries, construction, pharma,
  aviation) — multi-axis audience, numbering-as-locator,
  state machine lifecycle
- Generic organization methods (IA, faceted, topic maps,
  records management, SKOS, S1000D, FRBR, OAIS, DITA) —
  authoring/retrieval separation, arrangement primitives, CSP model

**Two pi-intercom reviews completed** on final contracts:
- Minion-1: Taxonomy should parent cross_cutting. 5 missing
  verification table dependencies. Delivery medium is biggest gap.
  Lifecycle over-engineered (15+ fields).
- Minion-2: Effectivity/applicability scope is #1 missing.
  Lifecycle biggest over-engineering offender. Numbering scheme
  dual role needs cleanup.

### Remaining

- **Fix lifecycle over-engineering** — make state machine fields
  conditional on `model: state_machine`. Most projects use continuous
  or ad_hoc and don't need states/transitions/gatekeepers.
- **Resolve taxonomy/cross_cutting boundary** — faceting belongs in
  taxonomy. Authority control and metadata_filtering placement still
  debated (minion-1 vs minion-2).
- **Trim cross-references** — keep model only (first_class, inline,
  none). Defer relationship types to implementation.
- **Add effectivity/applicability scope** — which product versions/
  configurations does a doc apply to? Distinguish from versioning
  and lifecycle.
- **Add delivery medium bridge** — Presentation layer in CSP model.
  How structure connects to PDF, web, paper, in-product.
- **Clean up numbering scheme dual role** — define once at
  organization level, reference from both authoring and retrieval.
- **Fix verification table dependencies** — 5 missing cross-stage
  connections from minion-1 review.
- **Authoring model options** — missing sequence and network types
- **Retrieval views** — missing network and matrix in enum
- **Define known-good default for small/simple projects** — still fog
