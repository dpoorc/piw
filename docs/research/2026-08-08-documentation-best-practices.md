# Documentation Best Practices — High-Stakes Environments and Communities

Research note for wayfinder ticket #4 (Documentation best practices in
high-stakes environments and communities). Findings from research by
documentation-intercom-2.

---

This report covers 6 domains: military, critical infrastructure, aerospace,
passionate communities, enterprise anti-patterns, and docs-as-code operations.
The synthesis at the end distills the findings into 21 requirements the
documentation meta-skill should incorporate.

## 1. Structural Patterns

### 1.1 The Diátaxis (Divio) Quadrant System

The most cited pattern across successful documentation projects. Four distinct
documentation modes, each with a unique purpose, voice, and audience:

| Mode | Oriented to | Must | Form |
|------|-------------|------|------|
| Tutorial | Learning | Allow newcomer to start | Lesson |
| How-to Guide | A goal | Solve a specific problem | Steps |
| Reference | Information | Describe machinery | Dry description |
| Explanation | Understanding | Provide context | Discursive explanation |

**Why it works:** Each mode has only one job. When modes mix, docs become
confused and hard to maintain. The structure tells the author how to write,
what to write, and where to put it.

**Adopted by:** Cloudflare (developer docs), Gatsby, Vonage, and hundreds of
projects.

**Skill recommendation:** The meta-skill should mandate classifying every new
page into one of these four quadrants. Refuse pages that try to be hybrid.

### 1.2 NASA Document-Type System

NASA Software Engineering Handbook (section 7.18) defines about 20 prescribed
document types with templates:

- SRS (Software Requirements Specification)
- SDD (Software Design Description)
- SUM (Software User Manual)
- STP/STR (Test Plan/Report)
- VDD (Version Description Document)
- SCMP (Software Configuration Management Plan)

Each has a **Data Item Description (DID)** — a template that specifies minimum
content, format, and review criteria. NASA inherits this from MIL-STD-498,
which used DIDs to make document requirements predictable across contractors.

**Pattern:** Prescribed templates + minimum content rules = predictable,
auditable docs. Every document of type X is guaranteed to contain sections A,
B, C.

**Anti-pattern:** Templates that are too rigid. MIL-STD-498 explicitly required
tailoring — projects could omit irrelevant DIDs by contract.

### 1.3 Space Architecture (Enterprise KB Design)

From Atlassian community research — a four-tier space model for maintainable
knowledge bases at scale:

- **Tier 1 — Company-wide spaces:** Handbook, org-wide policies. Tightly
  governed, specific owner.
- **Tier 2 — Functional team spaces:** Per-department docs. Clear ownership by
  default.
- **Tier 3 — Project/initiative spaces:** Temporary. MUST have archiving date
  set at creation.
- **Tier 4 — Personal spaces:** Drafts and working notes. Explicitly NOT
  official documentation.

**Pattern:** Naming tiers, lifecycle rules (Tier 3 expires), and ownership
boundaries prevent sprawl.

### 1.4 Three-Level Page Hierarchy

Within a space, a consistent three-level hierarchy:

- **Level 1 — Section pages:** Navigation only, no substantive content.
- **Level 2 — Topic pages:** The main content units. One topic per page.
- **Level 3 — Sub-pages:** Supporting detail, only when genuinely needed.

---

## 2. Ownership and Accountability Patterns

### 2.1 Named, Not Team Ownership

From enterprise KB research: **Space owners are named individuals, not teams.**
Teams diffuse accountability. A person (not a role) is accountable for periodic
audits of the space, standards for what belongs, and final calls on structure
and naming.

Page owners handle keeping individual pages accurate and flagging them for
archiving.

### 2.2 Wikipedia Dispute Resolution Model

Wikipedia has an escalation ladder for resolving doc disputes:

1. Direct talk page discussion (prerequisite for everything else)
2. Third opinion (3O) — an uninvolved editor weighs in
3. Requests for comment (RfC) — broader community input
4. Dispute resolution noticeboard
5. Mediation
6. Arbitration Committee (for intractable cases)

**Core rules:** Focus on article content, not on editor conduct. Assume good
faith. No personal attacks. Gradual editing, not edit wars.

**Skill recommendation:** Incorporate a lightweight dispute-resolution ladder.
First step is always "discuss on the page's talk/discussion thread." Escalate
to a maintainer vote if no consensus.

### 2.3 OpenStreetMap Wiki Conflict Resolution

OSM wiki guidelines call out:

- Conflicting information is very bad. Tagging recommendations must be
  consistent.
- Duplication is bad unless explicitly justified (different audience, different
  style — with cross-links).
- Proposals must be clearly identified as such and kept separate from
  established guidance.
- Template:merge is used to label pages needing reorganization.

---

## 3. Documentation Operations (Docs-as-Code) Patterns

### 3.1 Co-location Principle

From Sourcegraph: **Docs live in the same repo as code.** Not a separate repo.
When an engineer changes authentication flow, the auth docs should be right
there in the same PR. Separate repos create a gap where documentation debt
accumulates.

**Trade-off:** Raises the barrier for non-technical contributors (PMs, support)
who will not clone a repo. Mitigation is a web-based editing layer on top of
Git.

### 3.2 Automated CI/CD Quality Pipeline

From the docs-as-code pipeline research and GitLab implementation — run these
checks in CI on every doc PR:

1. **Spell checking** (CSpell) — Run only on changed files initially, not the
   whole corpus. Build a product dictionary organically.
2. **Link validation** (Lychee) — Accept 429 (rate-limited) as OK to avoid
   false failures.
3. **Style guide enforcement** (Vale) — Allows custom rule sets, enforces
   consistent voice.
4. **Markdown structure linting** (markdownlint) — Enforces consistent
   formatting.
5. **Mermaid diagram linting** — Validates diagrams render without syntax
   errors.
6. **Front matter checks** — GitLab requires every page has front matter with
   ownership metadata.
7. **Redirect checks** — When files are renamed or deleted, redirects must
   exist.
8. **Build verification** — A partial build validates all shortcodes and
   filenames work.

GitLab specific rules: curl commands must use long-form options, filenames
must be lowercase, \_index.md not README.md, image filenames must specify
version added.

### 3.3 PR Template for Docs

Include:

- What changed (brief)
- Why (most important field — connects the change to its trigger)
- Pages affected
- Checklist: Tested code examples, verified links, screenshots current,
  mobile/responsive check

---

## 4. Maintenance and Lifecycle Patterns

### 4.1 The Lifecycle Problem

Most documentation problems are not writing problems — they are **lifecycle
problems**. A page ships, the feature changes, nobody updates the page, a year
later docs contradict the product. The fix is structural, not editorial.

### 4.2 Drift Detection

From Sourcegraph: Treat docs and code as one searchable corpus. When an API is
renamed, search for its name across both code and docs. Use batch changes to
update doc references across repositories with a single declarative change.

### 4.3 Prescribed Expiry (Tier 3 Spaces)

Enterprise KB research: Project/initiative spaces need lifecycle rules set at
creation — either an archiving date or a quarterly review to determine
promotion, archiving, or deletion.

### 4.4 Wikipedia Page History and Talk Pages

Wikipedia provides:

- Full revision history for every page — complete accountability
- Talk pages for discussion separate from the content
- Watchlists for notification of changes
- Recent Changes feeds for monitoring

### 4.5 OSM Wiki Deprecation Markers

OSM wiki uses explicit deprecation tags and proposal markers to distinguish
current guidance from historical. Proposals must be clearly identified as
proposals.

---

## 5. Anti-Patterns (What Fails)

### 5.1 Enterprise Knowledge Base Failure Modes

Six root causes from Atlassian community research:

1. **Duplicate information** — Multiple teams document the same process. Nobody
   knows which is canonical.
2. **Stale pages with no owner** — Project ends, page stays. Pollutes search
   forever.
3. **Unclear ownership** — Everyone owns docs = nobody owns docs.
4. **Inconsistent naming/structure** — "Runbook" vs "Playbook" vs "SOPs" for
   the same content type.
5. **Knowledge silos** — Teams document for themselves, not the organization.
6. **Poor search** — Inconsistent titles, missing metadata, irregular tagging.

### 5.2 Documentation as an Afterthought

From Write the Docs principles: Document before you begin developing.
Early docs serve as spec drafts, facilitate peer feedback, and guide decisions.

### 5.3 ARID — Accept Repetition In Documentation

From Write the Docs: Strict DRY in docs leads to unreadable cross-reference
chains. Some information must be described again in documentation. The goal is
minimizing repetition, not eliminating it.

### 5.4 No Versioning

From Write the Docs: Consider incorrect documentation to be worse than missing
documentation. If you cannot keep docs current, version them with the software
so version 2.3 docs ship with version 2.3.

### 5.5 Confluence Sprawl

The tool is not the problem — the absence of deliberate structure is. Single
flat page lists, no space architecture, no ownership, no lifecycle = inevitable
decay.

---

## 6. Regulated Environment Patterns

### 6.1 FDA GxP: ALCOA Principles

Pharmaceutical documentation (21 CFR Part 211) requires data integrity via
ALCOA:

- **A**ttributable — Who did it? Signed/dated.
- **L**egible — Permanently readable.
- **C**ontemporaneous — Recorded at time of activity.
- **O**riginal — First record or certified copy.
- **A**ccurate — Free from errors.

Extended ALCOA+ adds: Complete, Consistent, Enduring (durable media),
Available (accessible for review).

**Skill recommendation:** ALCOA principles are directly applicable to
documentation quality. Attributable maps to page ownership. Contemporaneous
maps to versioning with the code. Legible maps to consistent formatting.

### 6.2 IEC 62304: Medical Device Software Documentation

Requires:

- Software life cycle plan
- Software requirements specification
- Software architecture description
- Software detailed design
- Software unit verification
- Software integration testing
- Software system testing
- Software release (version description, known defects)

All documentation must be traceable: requirements to design to tests. Each
requirement must be testable.

### 6.3 Aviation: ATA Spec 100 / iSpec 2200

ATA Spec 100 defines standardized content, format, and numbering for aviation
maintenance manuals. Key principles:

- Standardized chapter numbering — Chapter 24 is always "Air Conditioning"
  across all aircraft.
- Modular page structure — Pages are individually replaceable for revisions.
- Revision bars — Changed text is visually marked with bars in the margin.
- Effectivity coding — Clear indication of which aircraft/configuration a page
  applies to.

### 6.4 MIL-STD-961: Specification Format and Content

Establishes format and content for defense specifications:

- **Data Item Descriptions (DIDs)** — Standardized templates specifying exactly
  what information is required.
- **Tailoring** — The standard explicitly allows tailoring (omitting irrelevant
  sections by contract).
- **Strict section numbering** — Predictable navigation across all documents.
- **"Shall" language** — Requirements use "shall" (mandatory), "should"
  (desirable), "may" (optional).

---

## 7. Community Documentation Patterns

### 7.1 Wikipedia Manual of Style

Key governance mechanisms:

- Talk pages separate from content
- Edit summaries required — every change must be explained
- Consensus-based — no single editor has authority
- Gradual editing (BRD: Bold, Revert, Discuss)
- WikiProject system — topical groups maintain specific domains
- Citation requirements for contentious claims

### 7.2 Arch Linux Wiki Style

- Conventional headers for packages, installation, configuration
- Package templates — standardized infoboxes
- Help:Style — detailed style conventions
- Help:Procedures — documented processes for editing, flagging, merging
- Consistent article naming guidelines

### 7.3 OSM Wiki Guidelines

- Understandability — "Aim writing at level of children and grandmothers."
- Introduction pattern — every page starts with title in bold, short
  description, link to more general topic.
- Standardized linking templates
- Categories — single-line intro per category, categorized at most specific
  level only.
- Natural language page titles (no CamelCase).
- Explicit policies on external linking.

---

## 8. Synthesis: What the Documentation Skill Should Incorporate

Based on patterns that recur across all domains, the meta-skill should encode:

### Core Structural Requirements

1. **Document classification** — Every page is one of: Tutorial, How-to,
   Reference, Explanation. No hybrids.
2. **One topic per page** — Clear boundary prevents bloated pages.
3. **Standardized page anatomy** — Title in bold, intro paragraph, conventional
   section structure.
4. **Ownership metadata** — Every page has a named owner and a last-reviewed
   date.
5. **Lifecycle signals** — Pages can be marked: current, deprecated, draft,
   historical/archived.

### Process Requirements

6. **Docs-as-code workflow** — Co-located with code, PR-reviewed, CI-checked.
7. **Automated quality gates** — Spell check, link check, style lint, structure
   lint, diagram validation.
8. **PR template for docs** — Including a Why field connecting change to
   trigger.
9. **Lifecycle rules** — Tier 3 content gets expiry dates. Quarterly reviews
   for unowned pages.

### Governance Requirements

10. **Dispute resolution ladder** — Talk page to maintainer review to community
    vote.
11. **ALCOA data quality** — Attributable, Legible, Contemporaneous, Original,
    Accurate.
12. **Templates with prescribed minimum content** — Not rigid, but must include
    certain sections.
13. **"Shall"/"should"/"may" language** — Distinguishing mandatory from
    recommended from optional.

### Maintenance Requirements

14. **Versioning with releases** — Docs version with the software. Older
    versions remain accessible.
15. **Deprecation markers** — Clear visual distinction between current and
    superseded guidance.
16. **Change markers** — Changed sections visually indicated (revision bars
    concept from aviation).
17. **Cross-referencing discipline** — Main page to summary pattern. Link, do
    not duplicate.

### Community Requirements

18. **Contribution barriers minimized** — Web editing layer for non-developer
    contributors.
19. **Edit summaries required** — Every change explained.
20. **Consensus, not dictatorship** — Changes are proposed, discussed, agreed.
21. **Consistent linking conventions** — Standardized templates for common link
    patterns.

---

## Key Sources

- Divio Documentation System — <https://docs.divio.com/documentation-system/>
- Diátaxis framework — <https://diataxis.fr/>
- Write the Docs — Documentation Principles —
  <https://www.writethedocs.org/guide/writing/docs-principles/>
- Write the Docs — DocOps —
  <https://www.writethedocs.org/guide/doc-ops/>
- Docs-as-Code: Complete CI/CD Workflow —
  <https://dev.to/ekline/docs-as-code-the-complete-cicd-workflow-from-git-to-production-89b>
- Documentation as Code (Sourcegraph) —
  <https://sourcegraph.com/blog/documentation-as-code>
- GitLab Documentation Testing —
  <https://docs.gitlab.com/development/documentation/testing/>
- NASA SWE Handbook — Documentation Guidance —
  <https://swehb.nasa.gov/spaces/SWEHBVD/pages/102695654/7.18+-+Documentation+Guidance>
- Enterprise KB Failure Patterns (Atlassian) —
  <https://community.atlassian.com/forums/App-Central-articles/Why-Most-Enterprise-Knowledge-Bases-Fail-as-They-Scale-And-How/ba-p/3252504>
- Wikipedia:Manual of Style —
  <https://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style>
- OpenStreetMap Wiki Guidelines —
  <https://wiki.openstreetmap.org/wiki/Wiki_guidelines>
- Arch Linux Wiki — Help:Style —
  <https://wiki.archlinux.org/title/Help:Style>
- WHO Data Integrity Guidelines (ALCOA) —
  <https://cdn.who.int/media/docs/default-source/medicines/norms-and-standards/guidelines/inspections/trs1033-annex4-guideline-on-data-integrity.pdf>
- MIL-STD-961 —
  <https://quicksearch.dla.mil/qsDocDetails.aspx?ident_number=36063>
- ATA iSpec 2200 —
  <https://publications.airlines.org/products/ispec-2200-information-standards-for-aviation-maintenance-revision-2025-1>
