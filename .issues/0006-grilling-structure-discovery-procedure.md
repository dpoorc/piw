---
id: 6
title: 'Grilling: Structure discovery procedure'
status: in-progress
priority: high
labels:
    - wayfinder:grilling
    - docs
relations:
    depends-on:
        - 2
created: "2026-08-08"
updated: "2026-08-14"
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

### Progress this session (2026-08-13)

**All 9 gaps resolved — 6 commits to contracts document.**

| Tier | Items | Status |
|------|-------|--------|
| 1 (New concepts) | Effectivity, taxonomy boundary, delivery medium | ✅ |
| 2 (Simplifications) | Lifecycle conditional, cross-refs trimming | ✅ |
| 3 (Enum/field fixes) | Org groups, enums, verification tables | ✅ |

**Key structural changes to contracts:**
- Organization restructured: shared/authoring/retrieval groups
  (no single numbering_scheme field)
- Delivery section added between Architecture and Organization
- Lifecycle split into core + conditional state-machine fields
- Cross_cutting section eliminated, fields absorbed into taxonomy
  and retrieval.interface
- 7 missing verification table entries added
- Enums expanded with `etc` + `description: freeform`

**Contracts document now ~690 lines, ~85-90% complete.**
All sections filled, all cross-stage dependencies verified.
Remaining fog items captured below.

### Resolved

- ✅ **Fix lifecycle over-engineering** — state machine fields now
  conditional on `model: state_machine`. Core fields always present.
- ✅ **Resolve taxonomy/cross_cutting boundary** — eliminated
  `cross_cutting` section. Faceting → taxonomy, metadata_filtering →
  retrieval.interface, authority_resolution → retrieval.interface.
- ✅ **Trim cross-references** — model only (first_class, inline,
  none). Relationship types deferred to implementation.
- ✅ **Add effectivity/applicability scope** — added `effectivity`
  section to design output: model (inline/separate/none), axes,
  default. Added `constraints.effectivity` to discovery.
- ✅ **Add delivery medium bridge** — new `delivery` section between
  Architecture and Organization: `delivery.media[]` array with
  structural constraints.
- ✅ **Clean up numbering scheme dual role** — organization now uses
  shared/authoring/retrieval groups. Numbering scheme defined per
  group, not as a separate field.
- ✅ **Fix verification table dependencies** — 7 missing entries
  added across Discovery→Design and Init→Design tables.
- ✅ **Authoring model options** — expanded enum with sequence,
  network, and `etc` + `description: freeform`.
- ✅ **Retrieval views** — expanded arrangement enum with network,
  matrix, and `etc`.
- ⬜ **Define known-good default for small/simple projects** — still fog

### Remaining fog items

- Known-good default for small/simple projects
- Knowledge merging mechanism (reconciling contradictory artifacts)
- EOL procedure specifics (archive/redirect/delete)
- Handover packaging (structure across org boundaries)
- Domain-aware routing
- Regulatory sub-module interaction (separate module or part of discovery?)
