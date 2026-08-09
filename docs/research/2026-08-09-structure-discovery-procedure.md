# Structure Discovery Procedure

Working document capturing the structure discovery procedure for the
`documentation` skill. Synthesized from wayfinder ticket #6.
Last updated: 2026-08-09

---

## Overview

The structure discovery procedure is the core value proposition of the
`documentation` skill. It is a teachable, repeatable process for arriving
at a documentation structure for any project. It is not a prescriptive
template — it is a diagnostic and design process that adapts to the
project's scale, domain, and constraints.

The procedure has three phases:

```
Triage → Discovery → Design
```

Each phase produces output that feeds into the next. The procedure
writes decisions to `docs/meta/` as it goes, making it pause/resume
safe and stateful.

---

## Phase 0 — Triage

The triage classifies the project to route it to the appropriate branch
of the procedure. It asks 6 questions with free-form answers. The skill
interprets the answers, asks follow-up verification questions, and guides
the conversation toward the right path.

### Questions

1. **Describe the project in one sentence.**
   - The skill interprets the scale and domain from the description.
   - Examples:
     - "organizing my book collection" → small, likely 1 audience
     - "high-availability capability for a file-sharing app at company X"
       → medium, likely multiple audiences, team context
     - "joint effort between Siemens and Idaho water utilities to upgrade
       OT infrastructure" → large, regulated, multi-stakeholder

2. **Does documentation already exist?**
   - "No" → green-field, proceed to triage completion
   - "Yes, some" → ask about rough size, format, and location
   - "Yes, lots / chaos" (e.g., "3000 Confluence pages across 5 systems")
     → brown-field flag activated, will need a managed deliberate effort
     with phased approach

3. **What is the project domain?**
   - If unclear, the skill explains what "domain" means and helps the
     user figure it out.
   - Activates domain-specific modules (e.g., medical/regulated activates
     compliance module, software activates automation/integration advice).

4. **How many distinct audiences?**
   - The skill explains "audience" in this context before or alongside
     the question.
   - 1-2 audiences → simpler structure
   - 3-5 → moderate navigation complexity
   - 6+ → serious navigation and discoverability requirements

5. **What is the team capacity for maintaining documentation?**
   - One person, part-time, dedicated team, distributed contributors.
   - The skill reminds: "things will change in a year. Plan with headroom."

6. **Are there regulatory or compliance requirements?**
   - Activates regulatory module(s) if yes.
   - Routes to compliance-aware workflows regardless of project scale.

### Output

A triage record saved to `docs/meta/triage.md`:

```yaml
scale: small | medium | large
domain: software | hardware | research | community | regulated | other
brownfield: true | false
audience_count: 1-2 | 3-5 | 6+ | unknown
maintenance_capacity: solo | part_time | dedicated_team | distributed
regulatory: true | false | unknown
notes: "free-form notes from the conversation"
```

### Routing

Based on triage, the procedure routes to one of:

| Route | Criteria | Next step |
|-------|----------|-----------|
| **Small / simple** | Small scale, 1-2 audiences, no regulatory, green-field | Offer known-good default architecture (TBD — see fog items). Verification questions to confirm fit. |
| **Medium** | Medium scale, 3-5 audiences, OR some existing docs, OR team context | Full discovery → design cycle. |
| **Large / complex** | Large scale, 6+ audiences, OR regulatory, OR multi-stakeholder, OR brown-field chaos | Extended discovery with parallel work capability. Compliance modules active. Multiple design iterations expected. |

Each route acknowledges the procedure's own timeline. For large projects,
the discovery phase itself can take days or weeks.

---

## Phase 1 — Discovery

The discovery phase produces a requirements map. It answers: who reads
the docs, what do they need, what already exists, what constrains us,
what can go wrong?

### Audiences and needs

For each identified audience:

- What information does this audience need?
- When do they need it? (onboarding, daily work, troubleshooting,
  integration, audit)
- What format suits them best? (tutorial, how-to, reference, explanation,
  specification)
- What is their entry point to the project?
- What is their current frustration with existing docs (if any)?

### Existing artifacts inventory

What documentation already exists? In what form?

- Format: git repo, Confluence, wiki, PDF, paper, SharePoint, shared
  drive, oral tradition
- Quality: well-maintained, stale, contradictory, single-source-of-truth,
  guesswork
- Coverage: what areas are documented well, what gaps exist
- Ownership: who maintains each piece, if anyone

### Constraints

- Regulatory or standards requirements (FDA, MIL-STD, ATA Spec 100,
  IEC 62304, GDPR, etc.)
- Distribution medium (web, PDF, paper, in-product, API client)
- Versioning requirements (single version, branch-per-version, snapshot,
  regulated document control)
- Access control (public, internal, NDA, classified)

### Failure modes

For each major documentation area, assess risk:

| Failure mode | Likelihood | Impact | Priority |
|-------------|-----------|--------|----------|
| Docs get stale and mislead users | | | |
| New team members cannot onboard | | | |
| Regulatory audit finds gaps | | | |
| Users cannot find critical information | | | |
| Documentation contradicts itself | | | |

Use a simple high/medium/low or numeric scale. The goal is to identify
where investment matters most, not to produce exhaustive risk matrices.

### Output

Requirements map saved to `docs/meta/requirements.md`. Contains:
- Audience profiles with needs and formats
- Artifact inventory with quality assessment
- Constraint list
- Risk/priority assessment
- Known unknowns

---

## Phase 2 — Design

The design phase translates the requirements map into a concrete
documentation structure, taxonomy, and conventions.

### Structure architecture

Choose one or combine:

- **Diátaxis** (tutorial, how-to, reference, explanation) — good default
  for most projects
- **Domain/module-based** — structure mirrors project components
- **Audience-path-based** — structure follows reader journeys
- **Single-page** — for small bounded domains (SQLite model)

The choice is informed by audience complexity, domain, and existing
artifacts. The skill recommends Diátaxis as a default and explains when
alternatives fit better.

### Taxonomy and tags

Define categories or tags for cross-cutting concerns:

- By technology area (MDN sidebar model)
- By component or module
- By audience (beginner, expert, integrator)
- By doc type (tutorial, reference, changelog, etc.)
- By status (stable, deprecated, experimental)

Store in `docs/meta/taxonomy.md`.

### Navigation paths

Define entry points for each audience:

- "I am new to this project, where do I start?"
- "I need to fix a specific thing, where do I look?"
- "I need the complete reference, where is it?"

Define cross-linking conventions: "see also" sections, related pages,
next-page paths.

### Lifecycle model

Define how documentation moves through phases:

- Required stages (e.g., draft → review → current → deprecated →
  archived)
- Who is accountable at each stage
- Review cadence per section
- Expiration/review-by dates convention

### Load-bearing check

Before finalizing, verify: can the team maintain this structure?

- **High-churn content** (changes weekly): ruthlessly trim. If core,
  document and acknowledge maintenance burden. If auxiliary, leave it.
  If uncertain, skip.
- **Stable content** (won't change for years): document freely.
  LLM-assisted writing makes creation cheap, maintenance is minimal.
- **Omission ladder**: for anything uncertain — leave it. Shallow narrow
  docs are better than no docs.

### Output

Structure decision record saved to `docs/meta/structure.md`. Contains:
- Architecture choice and rationale
- File tree (or logical structure)
- Taxonomy/tag definitions
- Navigation paths and cross-linking conventions
- Lifecycle model
- Load-bearing assessment

---

## Statefulness

The procedure is stateful. Every decision is written to `docs/meta/` as
it is made. Future runs of the procedure (or other skill operations)
read from `docs/meta/` to understand the project's documentation
conventions.

The state machine supports pause/resume: if a discovery session runs
out of context or time, the next session reads `docs/meta/` and
continues from where it left off.

## Parallel work (large projects)

For large-scale projects, the discovery and design phases can be
parallelized across multiple parties. This requires:

- An issue tracker or equivalent coordination mechanism
- Defined groups of decisions that must be tackled by a single party
- A single source of truth (`docs/meta/`) that all parties write to

Issue tracking is surfaced as a prerequisite. Domains that do not use
issue trackers likely do not do parallel collaborative work of this
nature, so this requirement is self-limiting.

## Brown-field projects

Brown-field projects follow the same three-phase procedure but with
modifications:

- **Triage** activates the brown-field flag, which adds questions about
  existing docs volume, format, ownership, and quality
- **Discovery** includes an inventory and quality assessment of existing
  artifacts
- **Design** acknowledges that the full picture may never be available,
  and that progress must be made despite incomplete information
- The output includes a migration roadmap: what to keep, what to
  migrate, what to retire, what to create from scratch

See ticket #8 for the detailed brown-field migration strategy.

## Known-good default (fog item)

For small/simple projects (single person, 1-2 audiences, no regulatory,
green-field), the procedure may offer a known-good default architecture
instead of running the full discovery→design cycle.

The shape of this default is not yet defined. Candidate: a simple
tree structure with Diátaxis as the organizing principle and a small
set of recommended templates. Resolution deferred.

## References

- [Framework: invariants, values, principles](../2026-08-09-documentation-skill-framework.md)
- [Wayfinder map issue](.issues/0001-documentation-skill-design-wayfinder-map.md)
