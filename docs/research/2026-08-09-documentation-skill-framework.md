# Documentation Skill — Framework (WIP)

Working document capturing the current state of the `documentation` skill
design. Synthesized from wayfinder tickets #2, #3, #4, #5.
Last updated: 2026-08-09 (updated after roast evaluation)

---

## Invariants (matters of fact about documentation)

These hold regardless of domain, scale, or medium. The skill must accept
them as constraints and design around them.

| # | Invariant | Meaning |
|---|-----------|---------|
| 1 | **Documentation conveys information** | This is the purpose. It sets boundaries: documentation is not marketing, not customer support, not insurance. Does it affect those? Yes. But the core remains information transfer. Everything else evaluates against this. |
| 2 | **Documentation rots** | Entropy is inevitable. The cost of maintaining accuracy rises without active intervention. Rot IS the manifestation of unpaid maintenance cost. Keeping fresh (prevention) and restoring (correction) are different responses to the same problem. |
| 3 | **Documentation has multiple audiences** | As soon as two readers exist, you have multiple perspectives, contexts, and needs. At minimum you must be aware of this; ideally you design for it. |
| 4 | **Documentation can fail** | Wrong, stale, misleading, unfindable, incomprehensible, inaccessible, broken. Each failure mode suggests a principle to prevent or mitigate it. |
| 5 | **Documentation changes over time** | Content is written, updated, superseded, obsoleted. Temporal context is an inherent property, not an optional feature. |

## Values (what the skill should encourage)

These are aspirations the skill helps projects achieve. They anchor in the
invariants above.

| # | Value | Anchored in | Meaning |
|---|-------|-------------|---------|
| 1 | **Findable (internal)** | Invariant #4 (can fail — unfindable) | Readers can locate what they need inside the docs. Discoverability infrastructure, categories, taxonomy, indices. Distinct from navigable — you can find the right page but not know where to go from there. |
| 2 | **Navigable** | Invariant #4 (can fail — lost) | Readers can see relations between pages and follow paths. Cross-links, "see also", guided paths. Distinct from findable — you can move between related pages once on one. |
| 3 | **Teaches** | Invariant #1 (conveys information) | Goes beyond raw information transfer to genuine understanding. Examples, tutorials, progressive disclosure, context. |
| 4 | **Version-aware** | Invariant #5 (changes over time) | Actively tracking and communicating temporal context. Every page answers "what version/date range does this apply to?" |

## Derived principles (WHAT the skill should guide projects to do)

These are actionable responses to the invariants. They are abstract enough
to admit multiple implementations. The skill recommends a principle; the
project chooses how to implement it.

Principles are grouped by the invariant they respond to. Some principles
respond to multiple invariants — they appear under the strongest mapping.

### From "Documentation conveys information" (Invariant #1)

| Principle | Meaning | Implementation examples |
|-----------|---------|------------------------|
| **Purpose-driven format** | Content shaped by whether it teaches, references, instructs, or explains. A page that does not serve one of these purposes does not belong in the documentation system. | Diátaxis classification (recommended default); GNOME HIG pattern library format |
| **Omission discipline** | Not everything needs documentation. The best docs are ruthless about what they exclude. Know when to say no. | ARID (Accept Repetition In Documentation); minimum viable documentation principle; "document the interface, not the implementation" |
| **Tone and voice** | Documentation language serves clarity and information transfer. It is not marketing, not legal cover, not casual chat. Every writing convention should answer: does this help the reader understand? | Rails NOTE/TIP/WARNING conventions; OSM "write at level of children and grandmothers"; Vue "documentation is an exercise in empathy"; factual, imperative, active voice |
| **Visual communication** | When and how to use images, diagrams, annotated screenshots, and other non-text media. Visuals serve understanding, not decoration. | Blender manual annotated screenshots; GNOME HIG visual patterns; diagrams for relationships, text for definitions |

### From "Documentation rots" (Invariant #2)

| Principle | Meaning | Implementation examples |
|-----------|---------|------------------------|
| **Maintenance** | Documentation requires ongoing active care. This splits into three sub-functions: prevention, correction, and verification. | A maintenance plan with schedule, owner, and criteria |
| ├─ **Keep fresh** (preventive) | Regular reviews, freshness signals, automated checks. Stops rot before it sets in. | CI quality gates; calendar reminders; periodic human audit; frontmatter `last_reviewed` dates |
| ├─ **Restore** (corrective) | Restoring stale or broken documentation. Audit, assess, update, or archive. | Staleness scan; deprecation markers; archive procedure; refresh campaign |
| └─ **Verify** (quality) | Making sure the documentation is correct. Examples compile, procedures produce stated results, links are live. | Rust doc-tests; Django example CI; SQLite documented test methodology; link checkers |

### From "Documentation has multiple audiences" (Invariant #3)

| Principle | Meaning | Implementation examples |
|-----------|---------|------------------------|
| **Audience-aware structure** | Organize documentation so each audience has a clear path. Beginners, experts, integrators, maintainers — each needs a different entry point and depth. | Diátaxis quadrant (recommended default); Stripe guides-vs-reference split; per-audience entry points; scientific paper structure (abstract for all, methods for experts) |

### From "Documentation can fail" (Invariant #4)

| Principle | Meaning | Implementation examples |
|-----------|---------|------------------------|
| **Discoverability infrastructure** | Readers must be able to find content. This is broader than search — it covers anything that helps a reader locate the right page. | Table of contents; back-of-book index; chapter headers; search engine; taxonomy/category landing pages; breadcrumbs |
| **One topic per page** | Each page has one coherent subject. Meta-pages (indices, taxonomies, "how to use these docs") serve discovery and are separate. | Any page-per-concept convention; landing pages per category. Exception: bounded domains where a single page is more discoverable than many (SQLite SQL reference). |
| **Taxonomy** | Categories, tags, or other classification to group related content. | Arch Wiki category system; MDN sidebar per technology area; ATA Spec 100 chapter numbering |
| **Cross-linking discipline** | Related pages link to each other. Reader can follow paths between connected content. | "No stopping point" linking (Arch Wiki); auto-resolving cross-references (Rails); "see also" sections; "Next: X" at page bottom |
| **Accessibility** | Documentation must be consumable by all readers regardless of disability, device, or language. | Alt text for diagrams; screen-reader-compatible markup; color contrast; internationalization / localization; reading level targeting |
| **Feedback loops** | Mechanisms to detect whether documentation is working. Without measurement, every other principle is applied blind. | Usage analytics (Kedro); time-to-first-task tracking (Stripe); user research; issue tracker for doc bugs; reader surveys |

### From "Documentation changes over time" (Invariant #5)

| Principle | Meaning | Implementation examples |
|-----------|---------|------------------------|
| **Temporal context** | Every page answers "what version, date range, or applicability does this refer to?" | Frontmatter `valid_until` / `last_reviewed` dates; git tag association; version selector UI; inline "Since vX.Y" annotations; PCB revision markers |
| **Lifecycle management** | Documents progress through phases from creation to retirement. Each phase has different visibility, maintenance expectations, and access rules. | Lifecycle stages (draft → review → current → deprecated → archived) as one implementation; continuous wiki editing with flagging as another; FDA document control (draft → approved → current → obsolete, only current is served) |
| **Change governance** | Process for handling disputed or conflicting changes to documentation. Resolution must have a defined path. | Wikipedia escalation ladder (talk → 3O → RfC → arbitration); named owner as final decision-maker; editorial board vote |

### From "Documentation rots" + "can fail" (cross-cutting accountability)

| Principle | Meaning | Implementation examples |
|-----------|---------|------------------------|
| **Accountability** | Every documentation unit has a defined answerable party. Responsible for the unit's quality, correctness, timeliness, and lifecycle progression. The mechanism scales with project size and culture. | Small project: single person owns all docs. Medium project: per-section owners. Enterprise: doc manager + team liaisons. Software: CODEOWNERS per file pattern. Community wiki: diffuse responsibility with defined escalation path. Minimum test: "if a reader reports an error on this page, there is a defined person or process to handle it." |

## Implementation options (not universal principles)

These are specific mechanisms that the skill should mention as available
options but NOT prescribe as principles. They work in some contexts and
fail in others.

| Mechanism | Contexts where it works | Contexts where it does not |
|-----------|------------------------|---------------------------|
| **Docs-as-code** | Software projects with git and CI/CD | Hardware projects, regulated environments, multi-system enterprises, wikis |
| **Quality gates in CI** | Software documentation on git-based platforms | Paper docs, wikis without CI, non-software projects |
| **Diátaxis as hard rule** | Most software documentation; API/SDK docs | Projects where content mixes modes naturally (Rust Book, PostgreSQL), scientific papers, single-page references |

## Current frontier

**Resolved:**
- #3 (Finding great documentation examples) — 15 examples captured
- #4 (Best practices high-stakes/community) — 21 requirements synthesized
- #5 (Versioning mechanism) — 8-level taxonomy with scale framework
- #2 (Universal truths) — Framework refined after roast evaluation

**Resolved in this iteration:**
- Accountability — added as a principle under rots + can fail
- Contribution model — folds into lifecycle management (how content enters and moves through phases) and change governance (how disputes are resolved). Not a standalone principle.
- Progressive disclosure — implementation pattern for audience-aware structure. Not a principle.
- Consistent templates — implementation pattern for purpose-driven format. Not a principle.

**Still pending (need to develop or fold):**
- Cross-cutting patterns from research not yet incorporated:
  - Explicit style guides (partially covered under tone/voice, but the convention of *having* a documented style guide is separate)
  - Best-practice requirements: contribution barriers, edit summaries, anti-patterns (duplicate info, stale pages, knowledge silos)

**Next tickets (ready to claim):**
- #6 (Structure discovery procedure) — how the skill discovers project conventions
- #7 (Init module design) — how the skill initializes a project
- #8 (Brown-field migration) — blocked by #6

**Fog (map "Not yet specified"):**
- Knowledge merging mechanism
- EOL procedure specifics (depends on lifecycle definition)
- Taxonomy/tag convention (may resolve during #6)

## References

- [Research: Great documentation examples](../2026-08-08-great-documentation-examples.md)
- [Research: Best practices high-stakes environments](../2026-08-08-documentation-best-practices.md)
- [Research: Documentation versioning](../2026-08-08-documentation-versioning.md)
- [Roast evaluation](../2026-08-09-framework-roast.md)
- [Map issue](.issues/0001-documentation-skill-design-wayfinder-map.md)
