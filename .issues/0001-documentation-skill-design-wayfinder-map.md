---
id: 1
title: documentation skill design — wayfinder map
status: open
priority: high
labels:
    - wayfinder:map
created: "2026-08-08"
updated: "2026-08-15"
---

## Destination

A production-ready `documentation` skill that defines universal principles for project documentation. It is generic across domains (from a 3D-printed alarm clock to Apollo), lifecycle-aware (creation, maintenance, migration, EOL), opinionated but adaptable, meta-aware (discovers and integrates conventions from the project environment), and rooted in fundamentals rather than rigid templates. The existing WIP doc-writing skill is replaced entirely.

## Notes

**Skills to consult per session:** grilling, domain-modeling, research, prototype, ste-writing, writing-for-agents

**Domain:** Documentation meta-skill — documentation about documentation. The skill guides the practice of documentation itself, not just a template for writing docs.

**Standing preferences:**
- Establish universal truths first, then derive procedures from them
- Realistic about migration timeframes — brown-field adoption takes years
- Design for both green-field (new project) and brown-field (existing docs with history)
- The skill is referenced by other skills, never the reverse (except docs/meta)
- May become a standalone vendor skill project outside piw

## Decisions so far

- [Prototype walkthroughs](docs/research/2026-08-15-prototype-walkthroughs.md) —
  Resolved. 3 live role-play cases (Zara small greenfield, Marcus medium
  brown-field, Dr. Rivera regulated) executed per the contracts against
  naive-user personas. Known-good default seeded (v0.1), 13 divergences,
  6 contract defects, debrief findings.

- [Assumption review](docs/research/2026-08-15-assumption-review.md) —
  Resolved. A1 accepted (personas ~60-70% coverage, v1 is an iteration);
  A2/A7 deferred (more tests, timing open); A3 the skill is a wayfinder
  not a lexicon (authority discovery, gist-with-caveat); A4 contracts
  stay mutable; A5 known-good = light discovery + fallback shapes;
  A6 fields left as-is; A8 divergence unpacking in progress; A9 skill
  gains standalone harness-agnostic repo; A10 success criteria +
  budget-approval probe added. Flow control vs file architecture
  clarified: contracts describe WHAT/WHEN, never HOW the skill is
  packaged.

- [Research: Finding great documentation examples](.issues/0003-research-finding-great-documentation-exa.md) —
  Resolved. Found 15 excellent examples across 15 domains (Stripe, Rails,
  Vue, MDN, PostgreSQL, FreeBSD, Kedro, Arch Wiki, Django, Godot, Rust,
  SQLite, Blender, Terraform, GNOME HIG). Cross-cutting patterns identified:
  consistent templates, docs-as-code workflow, progressive disclosure
  (Diátaxis), explicit style guides, domain-modeled navigation, executable/
  verified examples, version discipline, audience segmentation.
  See [research/2026-08-08-great-documentation-examples.md](docs/research/2026-08-08-great-documentation-examples.md).

- [Research: Documentation best practices in high-stakes environments and
  communities](.issues/0004-research-documentation-best-practices-in.md) —
  Resolved. Synthesized 21 requirements across 5 dimensions (structure,
  process, governance, maintenance, community). Key patterns: Diátaxis
  quadrant system, NASA document types with DIDs, MIL-STD-961 tailoring,
  ALCOA data integrity principles, enterprise KB failure modes (6 root
  causes), Wikipedia dispute resolution ladder, OSM wiki guidelines, ATA
  Spec 100 revision bars, docs-as-code CI/CD pipeline.
  See [research/2026-08-08-documentation-best-practices.md](docs/research/2026-08-08-documentation-best-practices.md).

- [Research: Versioning mechanism for project documentation](.issues/0005-research-versioning-mechanism-for-projec.md) —
  Resolved. Produced 8-level taxonomy (Level 0: git-only through Level 7:
  regulated document control) with a decision framework by project scale.
  Key recommendation: versioning should match project scale — do not
  version prematurely. Universal invariant: every page must answer "what
  version/date range does this apply to?"
  See [research/2026-08-08-documentation-versioning.md](docs/research/2026-08-08-documentation-versioning.md).

- [Research: Universal truths of documentation](.issues/0002-research-universal-truths-of-documentati.md) —
  Resolved. Established 6 invariants, then refined after a fresh-context
  critical evaluation ("roast") to 5 invariants (conveys information, rots,
  multiple audiences, can fail, changes over time), 4 values (findable,
  navigable, teaches, version-aware), and ~15 derived principles (purpose-
  driven format, omission discipline, tone/voice, visual communication,
  maintenance (keep fresh + restore + verify), audience-aware structure,
  discoverability infrastructure, one topic per page, taxonomy, cross-
  linking discipline, accessibility, feedback loops, temporal context,
  lifecycle management, change governance, accountability). Structural
  issues fixed: merged redundant invariants (rot IS unpaid maintenance
  cost), rephrased "must reach" to "can fail", promoted "conveys
  information" from #6 to #1 as a boundary-setter.
  See [research/2026-08-09-documentation-skill-framework.md](docs/research/2026-08-09-documentation-skill-framework.md).

- [Grilling: Structure discovery procedure](.issues/0006-grilling-structure-discovery-procedure.md) —
  Claimed, in progress. Procedure skeleton designed through grilling:
  3 phases (Triage → Discovery → Design), 6 free-form triage questions
  routing to branches (small/medium/large), audience/artifact/constraint/
  failure-mode mapping in discovery phase, structure/taxonomy/navigation/
  lifecycle/load-bearing design in design phase. Key decisions: init
  includes triage (discovery is a separate module, confirmed Option C),
  stateful via docs/meta/ with pause/resume, omission ladder (high-churn →
  ruthless, stable → document freely, uncertain → skip), brown-field flag
  with phased approach, parallel work via issue tracker for large projects.
  See [research/2026-08-09-structure-discovery-procedure.md](docs/research/2026-08-09-structure-discovery-procedure.md).

- [Contracts document: Stage contracts for structure discovery procedure](.issues/0006-grilling-structure-discovery-procedure.md) —
  Resolved. The contracts document at ~690 lines now covers all stages
  (Init, Discovery, Design) with all sections filled and all cross-stage
  dependencies verified.
  See [research/2026-08-10-contracts-discovery-procedure.md](docs/research/2026-08-10-contracts-discovery-procedure.md).
  All 9 gaps from pi-intercom reviews resolved (see below).

- [Tier 1 resolution: Three new model concepts](.issues/0006-grilling-structure-discovery-procedure.md)
  — Effectivity/applicability scope (product version/document scope
  separation), taxonomy/cross_cutting boundary elimination (faceting
  absorbed into taxonomy, metadata/authority into retrieval.interface),
  and delivery medium bridge (Presentation layer, media[] with structural
  constraints).

- [Tier 2 resolution: Schema simplifications](.issues/0006-grilling-structure-discovery-procedure.md)
  — Lifecycle restructured to conditional model (core fields always
  present, state machine fields only when `model: state_machine`).
  Cross-references trimmed to model-only (inline, first_class, none).

- [Tier 3 resolution: Enum/field fixes](.issues/0006-grilling-structure-discovery-procedure.md)
  — Organization restructured with shared/authoring/retrieval groups
  (no single numbering_scheme field). Authoring enums expanded with
  sequence, network, etc. Retrieval arrangement expanded with network,
  matrix, etc. Verification tables filled (7 missing entries added).

## Not yet specified (fog)

- **Known-good default for small projects** — the procedure can route
  small/simple projects to a known-good default instead of running full
  discovery→design. Shape still not defined. Highest impact remaining fog.
- **Knowledge merging mechanism** — how does the "evolves" invariant work
  when large sums of new knowledge arrive? Still fog.
- **EOL procedure specifics** — what exactly happens at end-of-life?
  Archive? Redirect? Delete? Still fog.
- **Handover packaging** — structure across organizational boundaries.
  Still fog.
- **Domain-aware routing** — whether the procedure adapts behavior per
  domain (construction vs software vs medical). Still fog.
- **Regulatory sub-module interaction** — does discovery ask compliance
  questions, or is it a separate module? Still fog.

## Graduated from fog to ticket (new)

- **docs/meta format** — Now part of ticket #7 (Initialization module design).
- **Module architecture** — Now part of ticket #6 (Structure discovery procedure) and #7.

## Out of scope

- Pi-specific implementation details — the skill is generic and works outside piw
- Writing style rules — handled by the ste-writing skill
- Issue tracker choice and triage labels — handled by other conventions (but integration with them is in scope)
