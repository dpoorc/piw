# Skill production process — agreed outline

Date: 2026-08-17
Status: Agreed in discussion. Details pending resume.
Basis: post-#8 discussion between user and agent.

## Purpose

Defines how we produce the `documentation` skill artifact (SKILL.md
+ minimal support files) from the research-grade contracts and the
#7/#8 designs. The first draft will not be good. The process must
guarantee convergence to a good-enough state.

## The validation loop

```
Draft v0.1 → user review (batched) → v0.2 → Cold-model test
(5 scenarios, fresh sessions, contracts-closed)
    │
Gap list ←────────────────────────────┘
    │
Fix → v0.3 → re-test → ... → gates pass → ship v0.1
→ A1 post-v1 loop (real use)
```

**Core mechanism: the cold-model test.** All prior experiments ran
contracts-open (executor had the full contract text). The never-run
test: a fresh model reads ONLY the skill artifact and behaves like
those executors did. This test is the artifact's verification
mechanism. Everything else is hygiene.

## Three gates (all verifiable)

- **G1 — Hygiene:** zero decision-tracking references ("batch 2",
  "A4", "B5", "Option D", "TG-1"). Grep-able. Standing requirement 1.
- **G2 — Cold-model:** fresh session, contracts-closed, runs the
  scenario set. Behavior must match the contracts on exercised
  paths (route detection, probes, stop conditions, delivery, fog
  fallback). Divergence = gap list, not failure.
- **G3 — Neutrality pass:** structured, not vibes. Re-read the
  pre-A2 research (08-08, 08-09 docs), check each old finding has
  a home in the skill. Re-imports the early work that recent
  rulings dominate. Standing requirement 2.

## Good-enough bar for v0.1

1. G1-G3 pass.
2. Route map works cold: light route, full cycle, brown-field,
   hostile-exit, zero-budget (5 scenarios).
3. Interaction protocol holds cold: no interrogation on low-energy,
   no chasing on hostile, no pitch on firing, budget as constraint.
4. Known limits NAMED in the artifact. The spec'd-but-unexercised
   contract fields (taxonomy.scheme conventions, assignment
   auto/hybrid, delivery media in_product/obsidian_vault, lifecycle
   continuous/event_driven/ad_hoc/none, breadcrumbs non-none,
   retrieval.search=false) get a small "known limits" note.
   Deep validation of those is post-v1, inside the A1 loop.

## Bias-by-construction guard

The scenario set is derived from the route map's branches, not from
"what we learned recently". Structure-derived scenarios are neutral
by construction.

## Operational constraint

Deepseek-flash-tier degrades past ~150-200k context (todo.md
compaction-threshold issue). Cold tests run one scenario per fresh
minion, short sessions, to keep context low.

## Open questions (pending resume)

- **Q1 — Scenario set:** the 5 above — enough, or add one (e.g.,
  multi-speed/regulated high-stakes)?
- **Q2 — Client in cold tests:** scripted personas via minions
  (reproducible, like Run 1) vs user acting (realistic, like
  Run 2)? Lean: scripted for cold test, user debrief after.
- **Q3 — Artifact location:** iterate in workspace tree first, move
  to standalone repo at ship (A9 holds; harness-agnostic is a ship
  property, not a build property)? Lean: yes.
- **Q4 — Draft strategy:** one-pass draft v0.1 from the contracts,
  then batched user review (5-7 per batch)? Lean: yes.

## Status note

Paused 2026-08-17. User works in a separate session on ops:
(1) a sub-agents extension to piw/pi to replace intercom minion
management, (2) an auto-compact fix for the ~200k degradation.
The resolve of Q1-Q4 and the draft itself resume when the user
returns with those results.
