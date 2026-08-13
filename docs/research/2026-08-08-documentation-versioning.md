# Documentation Versioning — Taxonomy and Recommendations

Research note for wayfinder ticket #5 (Versioning mechanism for project
documentation). Findings from research by documentation-intercom-3.

> **Boundary note (added 2026-08-13):** This document covers **document
> revision mechanisms** — how documentation files are versioned,
> snapshotted, and maintained over time (Levels 0-7). It does NOT cover
> **product effectivity** — which product version or configuration a
> document describes (e.g., "this page describes API v2.1, not v1.0").
> Effectivity and document versioning are orthogonal concerns:
> a document at revision 4 may describe product v1, and a document
> at revision 1 may describe product v3. For effectivity modeling,
> see the contracts document at
> `docs/research/2026-08-10-contracts-discovery-procedure.md` (Design
> stage — `organization.effectivity`).

---

## Taxonomy of Approaches (Level 0–7)

### Level 0: No Versioning (Git-as-history only)

**How it works:** One docs site, one `docs/` folder. The only history is the
git log. Users always see whatever is current.

**Scale:** Single-maintainer projects, prototypes, tools with <100 users.

**Tradeoffs:**
- + Zero maintenance overhead
- + Works with any static site generator
- - No way for users on old versions to find matching docs
- - Silent drift: old content quietly becomes wrong

**When old docs and current code disagree:** The user loses. They follow
outdated instructions, it breaks, they file a bug or give up.

**Recommendation:** Acceptable only when (a) the project has no breaking
releases yet, or (b) the user base is small enough that the maintainer answers
questions directly. Document this choice explicitly in the README.

---

### Level 1: Inline Status Labels

**How it works:** Per-page or per-section annotations marking freshness status.
Examples: frontmatter dates (`last_reviewed`, `valid_until`), inline banners
("[Deprecated since v2.0]"), per-section version tags.

**Key patterns found:**
- MDN Web Docs: `experimental`, `deprecated` status labels per feature, plus
  Browser Compatibility Data (BCD) as structured JSON for per-browser,
  per-version support info.
- Wikipedia: Not used for versioning, but `{{update}}`, `{{outdated}}`,
  `{{obsolete}}` templates flag stale sections.
- Frontmatter pattern: `last_reviewed`, `valid_until`, `min_version`,
  `max_version`, `status: [stable|deprecated|experimental]`.

**Tradeoffs:**
- + No content duplication — one file covers all versions
- + Readers see everything in context
- - Unusable when behavior differs significantly between versions
- - Requires discipline to keep annotations current

**Recommendation:** Best for API reference pages and configuration docs where
features are additive. Combine with `last_reviewed` dates in frontmatter. Not
suitable for how-to guides or tutorials where exact steps must match the
version.

---

### Level 2: Git-Based (Docs-in-repo, tagged with releases)

**How it works:** Documentation lives in the same repository as code.
Versioning is implicit: every git tag is a doc snapshot.

**Key patterns:**
- Antora: Uses branches to store doc version lines.
- ReadTheDocs core: Versions are git tags and branches. When you push a tag,
  RTD builds docs from that tag.
- Doc Holiday / Doctave: Docs change in the same PR as code changes.

**ReadTheDocs version states:** Active / Inactive, Hidden / Not hidden, Public
/ Private.

**Tradeoffs:**
- + Zero additional infrastructure beyond git
- + Perfect fidelity — docs exactly match what was shipped with each release
- - Users need git literacy to browse old docs (unless a hosting layer is
  added)
- - No version selector UI unless you build one

**Recommendation:** The minimum viable versioning for any project with >1 major
release. For a single maintainer: tag docs alongside releases, point users to
"see docs for your version by checking out the tag."

---

### Level 3: Snapshot-Based (Docusaurus / GitBook pattern)

**How it works:** When you cut a new version, the entire current docs directory
is copied to a versioned folder (e.g., `versioned_docs/version-1.0.0/`). The
`docs/` folder becomes the current (next) version.

**Docusaurus specifics:**
- `versioned_docs/version-1.0.0/` = frozen copy at v1.0.0
- `docs/` = current development (served at `/docs/next/`)
- Strong recommendation: keep active versions below 10, ideally 2-3
- Guidance: "Don't version prematurely. Only version when you need to support
  multiple concurrent releases."

**Tradeoffs:**
- + Clean separation — each version is independently editable
- + Easy to backport fixes to old versions
- - Content duplication (ARID problem)
- - Maintenance burden scales linearly with active versions

**Recommendation:** Best for projects with 2-5 major versions concurrently
supported, where documentation changes substantially between versions. The 3-
tier recommendation (support current + 2 previous) is the sweet spot.

---

### Level 4: Full Semantic Versioning with Hosted Snapshots (ReadTheDocs)

**How it works:** Combines git-based origin with a hosting platform providing
automatic build per tag/branch, version selector UI, stable/latest conventions,
per-version search indexing, and deprecation banners.

**ReadTheDocs URL schemes:**
- Multi-version with translations: `/en/latest/`, `/en/1.5/`, `/es/latest/`
- Multi-version without translations: `/latest/`, `/1.5/`
- Single version: `/`, `/install.html`

**Tradeoffs:**
- + Full fidelity — docs built from the release tag
- + Best UX for end users (version switcher, banners, per-version search)
- - Infrastructure cost (hosted platform or self-hosted CI)
- - Build time grows with each version
- - Old versions may fail to build if the doc toolchain changes

**Recommendation:** Standard for any open-source project with broad adoption
(Python, pip, SQLAlchemy). The "stable + latest + N-2" pattern covers 95% of
users.

---

### Level 5: Per-Feature Compatibility Tracking (MDN/BCD pattern)

**How it works:** Beyond versioning whole documents, track individual feature
availability across versions as structured data. Features tagged with min/max
version per platform, status (experimental, deprecated, standard_track), and
implementation flags.

**BCD status transitions:** A feature stops being experimental when (1)
supported by default in 2+ major rendering engines, OR (2) supported by 1
engine for 2+ years with no major changes, OR (3) specification is unlikely to
change in breaking ways.

**Tradeoffs:**
- + Maximum precision — per-feature, per-platform, per-version
- + Structured data enables automated UI
- - High maintenance cost
- - Not suitable for procedural documentation

**Recommendation:** Only for projects where per-feature lifecycle tracking is
critical (libraries, frameworks, APIs published to an ecosystem). Maintain a
structured data layer separate from prose docs.

---

### Level 6: Full Revision History (Wikipedia pattern)

**How it works:** Every edit creates a permanent revision. Users can view full
edit history, diff any two revisions, link to a specific revision, restore
historical content.

**Tradeoffs:**
- + Complete audit trail
- - Storage cost: every edit stores the full page text
- - No concept of releases — history is a continuous stream
- - Hard to answer "what docs shipped with v1.0?"

**Recommendation:** Overkill for project documentation. Use the pattern for
internal docs where audit trails are required, but do not rely on it alone for
release-associated versioning.

---

### Level 7: Regulated Document Control (FDA 21 CFR Part 11 / ISO)

**How it works:** Formal document lifecycle management with unique document ID
per version, revision history table, formal review/approval workflow,
electronic signatures, audit trails, retention policies (no deletion, only
retirement).

**FDA 21 CFR Part 11 key requirements:** Complete copies in human-readable and
electronic forms, protection for accurate retrieval, time-stamped audit trails,
authority checks for access.

**Tradeoffs:**
- + Maximum rigor — full traceability
- - Extremely high overhead
- - Not suitable for fast-moving software projects

**Recommendation:** Only for regulated documentation. But borrow the concept of
explicit `valid_until` dates and formal revision history tables for any
document that makes safety-critical claims.

---

## Supplementary Mechanisms

### Wayback Machine (Fallback)

Set up automated capture of your docs site on the Wayback Machine after each
release. It is free and requires no maintenance. Use as a safety net, not a
primary versioning mechanism.

### Changelogs as Documentation Artifacts

Treat the changelog as a first-class versioning artifact. Every release should
produce a changelog entry that includes links to changed docs. Keep old
changelogs accessible.

---

## Decision Framework

| Scale | Users | Breaking changes | Recommendation |
|---|---|---|---|
| Solo prototype | <100 | None yet | Level 0 (git only) |
| Small OSS project | 100–1K | Rare | Level 1 (inline labels) + frontmatter dates |
| Growing OSS | 1K–10K | Regular (every few releases) | Level 2 (git-based, tag=version) + changelog |
| Popular OSS / small SaaS | 10K–100K | Structured (semver) | Level 3 (Docusaurus snapshot, 2–3 versions) |
| Major OSS (Python, pip) | 100K+ | Regular semver | Level 4 (RTD full hosted versioning) |
| Platform API (Stripe, MDN) | 1M+ | Multiple concurrent versions | Level 5 (per-feature compat tracking + hosted) |
| Regulated / compliance | Any | Any | Level 7 (formal document control) |

**Key rule:** Do not version prematurely. The cost of maintaining multiple doc
versions only pays off when you have a significant user base stuck on older
releases.

### Recommendations by Scale for the Meta-Skill

1. **Minimal** (<1K users, rare breaking changes): Git tag = version.
   Frontmatter `last_reviewed` dates. One docs page covers all versions with
   inline "Since vX.Y" annotations.
2. **Standard** (1K–100K, regular semver): Docusaurus-style snapshots. Keep
   current + 2 previous. Automate doc CI alongside code CI.
3. **Full** (100K+, API/SDK product): RTD-style hosting. Build per tag.
   Stable/latest/next conventions. Per-feature lifecycle metadata for core
   APIs.
4. **Maximum** (regulated): Formal document control process.

### Universal Invariant

Every page must be able to answer:

1. **Document revision**: "What revision of this document am I viewing?"
   — answered by git tag, frontmatter version field, or hosting UI.
2. **Product effectivity**: "Which product version or configuration does
   this document describe?" — answered by effectivity markers (see the
   contracts document for the effectivity model).

These are separate questions. A document at revision 4 may describe
product v1. A document at revision 1 may describe product v3. Do not
conflate them.
