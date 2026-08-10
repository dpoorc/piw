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
updated: "2026-08-10"
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

### Remaining

- Detail the discovery phase questions and output format
- Detail the design phase mechanics (requirements → structure mapping)
- Define the known-good default for small/simple projects
