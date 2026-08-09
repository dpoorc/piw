# Documentation Skill Framework — Roast Evaluation

Critical evaluation of the framework from `2026-08-09-documentation-skill-framework.md`
by documentation-intercom-1 (fresh context). Produced 2026-08-09.

---

## Key Gaps (Missing from the Framework)

1. **Search/discoverability** — Nothing about titles for search, metadata for
   indexing, SEO, search infrastructure, or synonym handling. Invariant #5
   carves out external discoverability as "out of scope" — this is a cop-out.
2. **Accessibility** — No mention of screen readers, alt text, color contrast,
   internationalization, or reading level targeting. GNOME HIG and MDN both
   have accessibility as core.
3. **Visual communication** — Entirely text-centric. Blender succeeds with
   annotated screenshots. No principle about when visuals serve better.
4. **Feedback loops** — No principle for measuring whether docs work. Kedro
   uses analytics; Stripe tracks time-to-first-call. Without feedback,
   principles are applied blind.
5. **Tone and voice** — Rails has NOTE/TIP/WARNING. Vue says "documentation is
   an exercise in empathy." OSM says "write at level of children." The
   framework has nothing on writing style.
6. **Contribution model** — How people contribute normally (not just dispute
   resolution). Wikipedia talk pages, MDN review gates, edit summaries.
7. **Testing docs** — SQLite documents test methodology. Rust has doc-tests.
   Django tests examples in CI. No principle about testing.
8. **What NOT to document** — Omission, triage, minimal viable documentation.
   ARID appears in research but not in the framework.

## Structural Issues

- **Invariants #1 (rots) and #3 (maintenance cost)** are the same — rot IS
  unpaid maintenance cost. Merge them.
- **Invariant #4 vs Value #4 (version-aware)** — value is just the imperative
  of the invariant. Redundant.
- **Invariant #6 (conveys information)** — content-free. It's the definition
  of documentation. Doesn't constrain anything.
- **"Must reach its audience"** is a goal, not an invariant. The invariant
  would be "docs can fail to reach their audience."
- **"Refresh"** is a procedure, not a principle. The deeper principle is
  "address documentation debt."
- **"Named ownership"** is an implementation of "accountability." Team,
  rotating, CODEOWNERS, and wiki models are alternatives.
- **"Lifecycle stages"** is an implementation of "document expiration."
  Wikipedia has no lifecycle stages.

## Tensions Not Acknowledged

- **Named ownership vs wiki models** — Wikipedia avoids page-level ownership.
  Diffuse responsibility is central to wiki success. Framework presents both
  without reconciling.
- **Change governance vs keep fresh** — Governance processes create friction.
  The more governance, the harder to keep docs current.
- **One topic per page + lifecycle + ownership** — Multiplicative overhead. 500
  pages × 3 states × 1 owner = 1500 tracking items. Fine at 20 pages. Breaks
  at 5000+.
- **Versioning snapshots + one topic per page** — Docusaurus-style snapshots
  duplicate every page per version. Narrow pages multiply the problem.

## Bias

- Framework is coded for software projects with git and CI/CD. Language is
  software-inflected ("PR", "CI", "co-located with code").
- The "non-principles" section signals awareness of context-dependence but
  cherry-picks — named ownership and lifecycle stages are equally context-
  dependent.
- Three research notes contain richer patterns than the framework absorbed
  (~60% capture rate).
- Versioning research (8-level taxonomy with scale framework) is reduced to
  one principle + one implementation example.

## Cross-Cutting Patterns from Research Not Incorporated

From the 15 examples research:
- Consistent templates per page/guide type — scattered across principles
- Progressive disclosure — nowhere in the framework
- Executable/verified examples — nowhere in the framework
- Explicit writing/style guide — nowhere in the framework

From the 21 best-practice requirements:
- ALCOA principles — not referenced
- Testing requirements — not referenced
- Contribution model — not referenced
- Anti-patterns (duplicate info, stale pages, knowledge silos) — not referenced

## Practical Concerns

- Named ownership for 20K-page Arch Wiki is impossible
- Diátaxis as "refuse hybrid pages" is too rigid — Rust Book and PostgreSQL
  both mix modes successfully
- One topic per page fails for SQLite's single-page reference
- Versioning language doesn't capture PCB revision model well
- Scientific research papers don't map to Diátaxis

## Concrete Fixes (Prioritized)

1. Add search/discoverability
2. Add accessibility/internationalization
3. Add feedback loops / measurement
4. Add tone/voice/writing style
5. Merge invariants #1 and #3
6. Demote "refresh" from principle to sub-procedure
7. Demote "named ownership" to implementation of "accountability"
8. Incorporate cross-cutting patterns from examples research
9. Re-label as software-first or add non-software companion
10. Add "what NOT to document" as a principle

The skeleton is solid. The stuffing is thin. ~60% complete.
