# Stage Contracts — Structure Discovery Procedure

Working document capturing the stage contracts for the `documentation`
skill's structure discovery procedure. Synthesized from tickets #6, #7,
and associated grilling sessions.
Last updated: 2026-08-11

---

## Overview

The structure discovery procedure has three stages:

```
Init (Stage 0) → Discovery (Stage 1) → Design (Stage 2)
```

Each stage produces a contract file in `docs/meta/`. The next stage
reads that file as its primary input. Stages are iterative — contracts
are refined as understanding deepens.

All contracts carry a `notes` field for free-form context that does
not fit the schema. Fog items are explicitly listed. This prevents the
schema from being a straitjacket and avoids software-only tunnel vision.

---

## Stage 0 — Init (Triage)

### Input

User answers to 9 free-form triage questions, guided by the skill:

1. Describe the project in one sentence.
2. Does documentation already exist? If yes, how much and in what form?
3. What is the project domain? (free-form, ambient context)
4. Who reads the documentation? How far apart are their backgrounds?
5. How many people work on the project? How many work on docs?
6. Are there regulatory or compliance requirements?
7. What is your timeline and budget for documentation?
   (tools, people, external help, deadline)
8. What is your team's relationship with documentation?
   (core practice, necessary task, afterthought, or hostile)
9. How often does this project change direction?
   (stable for years, quarterly releases, weekly pivots)

The skill interprets the answers conversationally and writes the triage
record below. The record is not a form — it is a structured summary of
the conversation.

### Output: `docs/meta/triage.md`

```yaml
description: "free-form project description - sets ambient context"
scale: small | medium | large            # derived by the skill
route: known_good | full_cycle | extended  # derived from scale + flags

brownfield:
  exists: true | false | partial
  volume: unknown | light | moderate | heavy | catastrophic
  format: "description of format and location"
  note: "free-form on ownership, disarray level, migration history"

audiences:
  groups:
    - "description of each audience group"
  cognitive_distance: low | medium | high
    # low = all audiences share a background (e.g., all engineers)
    # medium = some overlap, some distinct (e.g., engineers + ops)
    # high = fundamentally different (e.g., engineers + executives + regulators)
  note: "free-form on audience dynamics, politics, access patterns"

maintenance:
  project_size: <number>      # total people working on the project
  doc_dedicated: <number>     # people dedicated to docs full-time
  doc_partial: <number>       # people who do docs as part of their work
  pattern: dedicated | ad_hoc | distributed | project_is_docs | outsourced | zero | rotational | community | institutional | passionate_volunteer | ghost
    # dedicated = one person owns docs full-time
    # ad_hoc = docs happen when someone has time
    # distributed = docs are everyone's second job
    # project_is_docs = the project IS documentation (wiki, standards body)
    # outsourced = maintained by external vendor/agency
    # zero = nobody maintains docs (common in early startups)
    # rotational = ownership rotates every quarter
    # community = maintained by external contributors
    # institutional = maintained by a standards body on a fixed cycle
    # passionate_volunteer = one person writes docs because they care
    # ghost = docs exist but nobody knows who maintains them
  note: "free-form on doc culture, bottlenecks, skill gaps"

regulatory:
  active: true | false
  frameworks: ["list of applicable frameworks, if known"]
  note: "free-form on audit needs, retention rules, legal review"

budget:
  timeline: "when does this need to be done? (deadline, target date)"
  resources: "what budget for tools, people, external help"
  note: "free-form on constraints, dependencies, approvals needed"

culture:
  priority: core | important | necessary | afterthought | hostile
  note: "free-form on team's relationship with documentation"

volatility:
  pace: stable | slow | moderate | fast | chaotic
  note: "how often the project changes direction or releases"

# ── Fog items ──
# Things we know we don't know about this project
fog:
  - "who owns the existing documentation?"
  - "is there institutional knowledge not captured anywhere?"
  - "has there been a previous attempt to reorganize?"

# ── Free-form overrides ──
# Anything that doesn't fit the schema. Allows projects outside
# software (hardware, construction, medical, policy) to attach
# their own context without forcing it into software-shaped fields.
notes:
  - "any additional context the user volunteered"
  - "gut feelings from the skill about risks or opportunities"
```

### Key design decisions

- **Domain is not categorical.** The free-form `description` carries
  ambient context. The skill reads it to tailor language and
  recommendations. Only regulatory triggers structural overrides.
- **Cognitive distance replaces audience count.** The number of
  audiences is less important than how far apart they are.
- **Brownfield volume estimates effort.** `heavy` or `catastrophic`
  volume tells discovery to budget significant inventory effort.
- **Maintenance pattern captures docs culture.** 11 patterns cover
  the range from dedicated teams to ghost docs. The `project_is_docs`
  pattern handles wiki-like efforts where documentation IS the work.
- **Budget and timeline constrain every downstream decision.** The
  procedure must respect the project's time and resource boundaries.
- **Documentation culture predicts adoption resistance.** A
  `hostile` culture requires different recommendations than a `core`
  culture.
- **Volatility churn rate drives architecture.** Fast-changing
  projects need modular, swappable pages. Stable projects can afford
  monolithic reference docs.
- **Every section has a notes field.** Prevents schema from being a
  straitjacket.

### Fog items (universal, not project-specific)

- Known-good default for small/simple projects (shape not yet defined)
- How to handle "unknown unknowns" in triage (user doesn't know their
  own audience or regulatory requirements yet)
- How the budget/timeline field interacts with the known-good default
  (should a tight deadline route directly to known-good?)

---

## Stage 1 — Discovery

### Input

`docs/meta/triage.md` from Stage 0. The triage record provides the
initial classification, audience sketch, and constraints.

### Process

An extended structured conversation. For each area, the skill asks
free-form questions, interprets the answers, and writes the
requirements map.

**Handling "I don't know."** When the user cannot answer a question,
the skill records it as fog with a conservative default assumption.
Critical gaps (brownfield status, regulatory applicability) require
resolution — the skill flags these and offers suggestions for finding
the answer. Non-critical gaps (exact audience count, precise
maintenance capacity) stay as fog and the procedure continues.
The conversation naturally distinguishes the two.

**Scale-aware depth.** The depth of discovery adapts to triage scale:

- **Small** — 1-2 questions per area, minimal audience deep-dive,
  quick constraint scan, no failure mode assessment.
- **Medium** — Full depth: 3-5 questions per audience, complete
  artifact inventory, constraint scan, failure mode assessment.
- **Large** — Extended depth: 5+ questions per audience, tiered
  artifact inventory (sample heavy areas exhaustively, others broadly),
  full constraint analysis with regulatory module, failure mode
  assessment with priority ranking.

### Output: `docs/meta/requirements.md`

```yaml
# ── Audience deep-dive ──
# Multi-axis model: audiences are separated by multiple dimensions,
# not just role. Common axes: role, clearance, lifecycle phase,
# technical level, language, product variant.
# The project defines its own axes — the skill offers templates.
audiences:
  axes: ["role", "clearance", "phase"]  # dimensions that separate audiences
  entries:
    - id: <unique-identifier>
      axis_values:
        role: "operator"
        clearance: "unclassified"
        phase: "daily"
      identity: "who they are (free-form description)"
      needs:
        - description: "what information they need, in the user's own language"
          format: tutorial | how_to | reference | explanation | specification
          # The skill maps user-described needs to phases internally
          # (onboarding, daily, troubleshooting, audit, integration)
          # for Diátaxis classification. The user never sees phase labels.
      entry_point: "where they first look for documentation"
      frustrations: "what is broken or missing today"
      note: "free-form on their technical level, doc literacy, language"

# ── Artifact inventory ──
# What already exists. Includes non-digital artifacts (paper,
# whiteboards, oral tradition).
artifacts:
  - description: "what this artifact is"
    location: "where it lives (URL, path, physical location)"
    format: git | confluence | wiki | sharepoint | pdf | paper | oral
    quality: maintained | stale | contradictory | single_source | unknown
    owner: "who maintains it, if known"
    note: "free-form on why it exists, how it is used, gaps it fills"

# ── Constraints ──
# External forces that shape what documentation can look like.
constraints:
  regulatory: ["list of regulatory requirements that apply"]
  distribution: ["how docs must be delivered - web, PDF, paper, in-product"]
  versioning: ["how docs must be versioned - single, branch-per-version, snapshot, regulated"]
  effectivity:  # product/configuration scope of documentation
    needed: true | false
    axes: ["version", "serial_number", "date_range", "hardware_revision", "environment"]
    note: "which configurations the project distinguishes and how they are identified"
  access: ["who can see what - public, internal, NDA, classified"]
  tooling: ["required platforms - Jira, SharePoint, DocuSign, etc."]
  note: "free-form on integration pain points, mandatory workflows"

# ── Failure modes ──
# Where can documentation fail, and what is the impact?
failure_modes:
  - area: "description of the doc area at risk"
    likelihood: low | medium | high
    impact: low | medium | high | critical
    priority: low | medium | high | critical
    note: "what happens when this fails"

# ── Known unknowns ──
# Things discovery could not resolve. These feed back into the
# fog list and may be resolved in future iterations.
unknowns:
  - "specific question that remains open"
  - "potential information source to check"

# ── Free-form overrides ──
notes:
  - "anything that does not fit the above"
```

### Key design decisions

- **Audiences use a multi-axis model, not flat roles.** The project
  defines its own separation axes (role, clearance, phase, language,
  etc.). The skill offers common templates. This handles both simple
  (users vs admins) and complex (role × clearance × variant) cases.
- **Discovery depth matches triage scale.** Small projects get
  lightweight discovery with fewer questions. Medium and large
  projects get proportional depth.
- **Artifacts include non-digital.** Paper, whiteboards, oral
  tradition are valid documentation formats.
- **Failure modes use a simple three-level scale.** High/medium/low
  is enough to prioritize. Certainty is not required — estimates are
  fine.
- **Known unknowns are explicit.** They become fog items for the
  project and targets for future discovery rounds.
- **Configuration coupling is a conversation topic, not a field.**
  If documents must track a specific product version or configuration
  baseline, discovery explores this conversationally. The answer
  shapes design choices (branch-per-version tree, configuration
  markers on pages) without needing a dedicated schema field.

### Fog items

- Exact fields for audience needs by lifecycle phase (is the list of
  phases complete? Are the format options right?)
- How to handle discovery when the user cannot articulate audience
  needs (common in early-stage projects) — "I don't know" is fog,
  handled via the same fog mechanism as wayfinder
- How discovery interacts with regulatory modules (should discovery
  ask regulatory-specific questions, or leave that to a separate module?)
- Knowledge merging mechanism — how does discovery reconcile
  contradictory artifacts or conflicting audience needs?

---

## Stage 2 — Design

### Input

`docs/meta/triage.md` (scale, route, maintenance) +
`docs/meta/requirements.md` (audiences, artifacts, constraints, risks)

### Output: `docs/meta/structure.md`

```yaml
# ── Architecture ──
# The organizing principle for the documentation.
architecture: diataxis | module_based | audience_path | single_page | hybrid
rationale: "why this architecture fits this project"

# ── Organization ──
# How documents are organized and retrieved.
# Separates authoring (maintenance) from retrieval (finding).
# Supports six arrangement types: hierarchy, sequence, network,
# flat_set, matrix, numbering_scheme.
organization:
  arrangement_types: ["hierarchy"]
  # Which structural primitives this project uses
  
  authoring:  # how maintainers organize documents
    model: file_tree | numbering_scheme | flat
    # model = file_tree:
    tree:
      - docs/
        - index.md
        - tutorials/
        - how-tos/
        - reference/
        - explanation/
        - <domain-specific-sections>/
        - changelog.md
    # model = numbering_scheme:
    numbering_scheme:
      pattern: "encoding logic (e.g., ATA chapter, MasterFormat, TM number)"
      allocation: "how numbers are assigned and tracked"
    # model = flat:
    flat_description: "all documents in a single pool, organized by tags"
    note: "free-form on authoring workflow, version control"
  
  retrieval:  # how users find documents
    views:
      - audience: <audience-id>
        arrangement: hierarchy | sequence | numbering | flat
        entry: "where this audience enters"
        path: ["ordered documents or sections"]
    search: true | false
    note: "free-form on retrieval behavior, search limitations"
  
  cross_cutting:  # modifiers that apply across arrangements
    tagging: true | false
    faceting: true | false
    facet_dimensions: ["audience", "component", "status"]
    metadata_filtering: true | false
    authority_control: true | false
    note: "how cross-cutting modifiers are implemented"
  
  effectivity:  # which product versions/configurations docs apply to
    model: inline | separate | none
    # inline = each document declares its own scope (frontmatter)
    # separate = effectivity matrix maintained separately
    # none = all docs apply universally (default, no config-specific docs)
    axes: ["version"]
    default: all | current | named
    # all = docs apply to all versions by default
    # current = docs apply only to current version
    # named = each document must explicitly declare its effectivity
    note: "how applicability is declared, which axes matter"

# ── Taxonomy ──
# Classification scheme for documents.
# Type determines how categories relate to each other.
taxonomy:
  type: hierarchical | faceted | thesaurus | flat_controlled
  tags: ["tag1", "tag2", "tag3"]
  convention: frontmatter | separate_index | sidebar
  note: "free-form on taxonomy design, hierarchy, naming conventions"

# ── Template governance ──
# How document structure is enforced.
template_governance:
  tier: 0 | 1 | 2 | 3
  # 0 = free-form (personal notes, no enforced structure)
  # 1 = guidelines (recommended sections, not enforced)
  # 2 = enforced (prescribed sections, fields, formatting)
  # 3 = regulated (templates are controlled documents with revision history)
  note: "which tier applies to which document types, any exceptions"

# ── Navigation ──
# Intra-document navigation conventions (finding aids within a view).
# Entry points per audience are captured in organization.retrieval.views.
navigation:
  conventions:
    cross_reference: "see-also sections | related pages"
    next_page: "logical next-step links"
    breadcrumbs: "path-based | tag-based | none"
    note: "free-form on navigation patterns, search integration"

# ── Cross-references ──
# Structured relationships between documents.
cross_references:
  model: first_class | inline | none
  # first_class = structured data with relationship types, queriable
  # inline = within-text hyperlinks only
  # none = no cross-referencing convention
  relationship_types:
    - depends_on       # Document A requires Document B
    - see_also         # Related but not required
    - supersedes       # Document A replaces Document B
    - superseded_by    # Document A is replaced by Document B
    - describes        # Document A describes Component X
    - referenced_by    # Document A is referenced in Document B
  note: "how cross-references are maintained, verified, and reported"

# ── Lifecycle ──
# How documentation changes over time.
# A state machine is the default implementation, but not a requirement.
# Projects may use continuous updates, event-driven revisions,
# ad-hoc maintenance, or no formal lifecycle at all.
lifecycle:
  model: state_machine | continuous | event_driven | ad_hoc | none
  # state_machine = staged progression (draft → review → current → archived)
  # continuous = live editing with no formal stages
  # event_driven = updates triggered by specific events (release, audit)
  # ad_hoc = updates happen when someone has time
  # none = no lifecycle management (not recommended)
  default_states:  # applies when model = state_machine
    - draft       # being written, not yet reviewed
    - review      # under review by designated gatekeepers
    - approved    # reviewed and approved, awaiting effective date
    - current     # effective, published, in active use
    - deprecated  # still usable but superseded by newer content
    - archived    # historical record, no longer recommended
  transitions:  # applies when model = state_machine
    draft → review:       submit_for_review
    review → draft:       request_changes
    review → approved:    approve (gatekeeper required)
    approved → current:   activate (on effective date)
    current → deprecated: supersede
    current → archived:   eol_direct
    deprecated → archived: retire
  gatekeepers:  # applies when model = state_machine
    review: ["editor", "subject_matter_expert"]
    approve: ["document_owner", "compliance_officer (if regulatory)"]
    note: "free-form on gatekeeper roles, review boards, exceptions"
  effective_dating:
    supported: true | false
    default: approval_date | effective_date
    note: "how effective dates are assigned, deferred activations"
  audit_trail:
    supported: full | transitions | none
    # full = every state transition logged with actor, action_type, timestamp
    # transitions = major transitions (approve, activate, retire) logged
    # none = no logging required
    note: "who logs what, retention requirements, tool support"
  review_cadence: quarterly | monthly | per_release | event_driven | none
  expiry: "every page carries a review-by date | no expiry"
  supersession: "obsolete documents retain supersession links to their replacement"
  note: "free-form on review workflow, exceptions, alternative models"
  accountability:
    model: named_owner | team_ownership | codeowners | distributed
    note: "how accountability is assigned and enforced"

# ── Load-bearing check ──
# Can the team maintain this structure?
load_bearing:
  assessment: "can the identified team maintain this structure?"
  risk: "what breaks first if capacity drops"
  mitigation: "what can be trimmed or deferred"
  note: "free-form on structural risk"

# ── Free-form overrides ──
notes:
  - "anything that does not fit the above"
```

### Key design decisions

- **Architecture is a recommendation, not a rule.** Diátaxis is the
  default, but the skill explains alternatives and the project chooses.
- **Organization separates authoring from retrieval.** How maintainers
  organize documents (authoring) may differ from how readers find them
  (retrieval). Both must be described. The old `file_tree` is now one
  sub-field of `organization.authoring.model`.
- **Organization supports six arrangement types.** Hierarchy, sequence,
  network, flat_set, matrix, and numbering_scheme. A project may use
  one or more. The skill discovers which types apply during discovery.
- **Cross-cutting modifiers (tags, facets, search, metadata filtering,
  authority control) apply across all arrangement types.** They are not
  arrangements themselves but modifiers that enhance any primary
  structure.
- **Taxonomy type distinguishes how categories relate.** Hierarchical,
  faceted (orthogonal dimensions), thesaurus (associative relationships),
  and flat controlled vocabularies (no hierarchy) have different
  properties and require different discovery questions.
- **Lifecycle management is the principle; stages are one implementation.**
  The skill offers a state machine as default (draft → review → approved →
  current → deprecated → archived) but accepts alternatives: continuous
  editing, event-driven updates, ad-hoc maintenance, or no formal lifecycle.
  Regulated projects typically need the state machine. Small projects may
  use continuous or none.
- **Template governance tiers prevent schema fatigue.** Regulated
  projects need enforced templates (Tier 3). Personal notes need none
  (Tier 0). The same contract schema supports all tiers.
- **Cross-references are first-class data, not just hyperlinks.**
  Structured relationship types (depends_on, supersedes, describes)
  enable impact analysis: "if document A changes, which documents must
  be updated?"
- **Effective dating separates approval from activation.** A document
  can be approved but not yet in effect. This handles scheduled
  deployments and regulatory transition periods.
- **Audit trails are a structural requirement for regulated projects.**
  State transitions must be logged with actor, action type, and timestamp.
- **Retirement never means deletion.** Obsolete documents retain
  supersession links to their replacement. Historical preservation
  is the default.
- **Load-bearing check is mandatory.** Every design must assess
  whether the team can maintain it. High-churn content gets trimmed
  ruthlessly.
- **Effectivity is distinct from document versioning.** Document
  versioning tracks revision history of the document itself (Levels 0-7
  in the versioning research). Effectivity tracks which product version
  or configuration the document describes. A document at revision 4
  may still describe product v1. A document at revision 1 may describe
  product v3. These dimensions are orthogonal and should not be conflated.
- **Effectivity is distinct from lifecycle effective dating.**
  Effective dating answers "when does this document become active?"
  Effectivity answers "which configurations does this document describe?"
  They interact — a document can be effective for v2 but not for v1 —
  but they are separate concerns that must be modeled independently.
- **Effectivity axes are project-defined.** The axes that distinguish
  one configuration from another (version, serial number range, hardware
  revision, environment, date range) are specific to the project's
  domain. The skill does not prescribe them — discovery asks what axes
  matter and records them.
- **Effectivity enables document reuse across configurations.** The
  ceiling model (S1000D) authors each data module once with effectivity
  codes. Different publications filter by effectivity to include only
  applicable modules. Simpler projects use inline frontmatter. The
  principle is the same at every scale: author once, apply to many.

### Fog items

- EOL procedure specifics (what happens at end-of-life — archive,
  redirect, delete) — `archived` is in the state machine but the
  exact procedure (retention period, format migration) is not defined
- Taxonomy/tag convention details (how tags are expressed —
  frontmatter, separate index, sidebar)
- How to handle multiple architectures in one project (e.g., Diátaxis
  for user docs, module-based for internal API docs)
- Numbering scheme integration — how numbering schemes coexist with
  other arrangement types (now partially addressed by
  `organization.authoring.numbering_scheme`)
- Delivery medium bridge — how structure maps to PDF, web, paper, or
  in-product delivery (the CSP model's Presentation layer)
- Handover packaging — how documentation structure changes when
  delivered across organizational boundaries

---

## Cross-stage contract verification

### Init → Discovery

| Init field | Discovery use | Status |
|-----------|---------------|--------|
| `description` (domain) | Ambient context for tailored questions | ✅ Free-form, no loss |
| `brownfield.volume` | Budget artifact inventory effort | ✅ Covers skirmish→war |
| `audiences.groups` | Starting point for deep-dive | ✅ Discovery expands these |
| `audiences.cognitive_distance` | Suggests depth of audience separation in design | ✅ Indirect (via design) |
| `maintenance.pattern` | Not directly used by discovery | ⚠️ Discovery doesn't need this; design does |
| `regulatory.active` | Activates regulatory discovery questions | ❓ Does discovery ask regulatory questions, or does a separate module? |
| `budget.timeline` | Informs discovery scope (tight deadline = skip optional questions) | ✅ Direct |
| `culture.priority` | Informs discovery depth (hostile culture → minimal recommendations) | ✅ Direct |
| `volatility.pace` | Informs discovery focus (fast churn → emphasize modularity) | ✅ Direct |

**Open question:** should discovery have its own regulatory sub-module
that asks compliance-specific questions, or does discovery note the
regulatory flag and the compliance module runs separately? This is a
fog item.

### Discovery → Design

| Discovery field | Design use | Status |
|----------------|-----------|--------|
| `audiences[].needs[]` | Informs architecture choice (Diátaxis quadrant per need) | ✅ Direct mapping |
| `audiences[].entry_point` | Informs retrieval views (where each audience enters) | ✅ Updated — feeds `organization.retrieval.views[].entry` |
| `artifacts[]` | Informs migration plan, what to keep/retire | ✅ Indirect (via structure) |
| `constraints.regulatory` | Forces lifecycle stages + archival rules | ✅ Direct |
| `constraints.regulatory` | Drives template governance tier (regulated = Tier 3) | ✅ Direct |
| `constraints.versioning` | Informs lifecycle and organization authoring model | ✅ Direct |
| `constraints.distribution` | Informs delivery medium bridge | ⚠️ Presentation layer not yet defined — fog item |
| `failure_modes[].priority` | Informs load-bearing check priorities | ✅ Direct |
| `constraints.effectivity.needed` | Drives `organization.effectivity.model` (needed=true → inline or separate; needed=false → none) | ✅ New — direct |
| `constraints.effectivity.axes` | Drives `organization.effectivity.axes` | ✅ New — direct |
| `unknowns` | Becomes fog items for the project | ✅ Direct |

### Init → Design

| Init field | Design use | Status |
|-----------|-----------|--------|
| `scale` | Complexity of file tree | ✅ Direct |
| `maintenance.pattern` | Load-bearing check | ✅ Direct |
| `maintenance.project_size` | Load-bearing check | ✅ Direct |
| `route` | Whether to run full design or offer known-good default | ✅ Direct |
| `budget.timeline` | Influences load-bearing check (tight deadline = trim scope) | ✅ Direct |
| `budget.resources` | Influences template governance tier (no budget = Tier 0 or 1) | ✅ Direct |
| `culture.priority` | Influences load-bearing check (afterthought = trim scope) | ✅ Direct |
| `volatility.pace` | Influences architecture choice (high churn = modular) | ✅ Direct |
| `volatility.pace` | Influences organization arrangement types (high churn → hierarchy + search, stable → numbering_scheme) | ✅ Direct |

---

## Project fog (dynamic, project-specific)

Each project accumulates fog items as the stages run. These are
recorded in the respective contract files and persist across sessions.

Universal fog items (apply to all projects, may never resolve):

- Known-good default for small/simple projects
- Knowledge merging mechanism (reconciling contradictory artifacts)
- Regulatory sub-module interaction (does discovery ask compliance
  questions, or is it a separate module?)
- Numbering scheme integration (now partially addressed by
  `organization.authoring.numbering_scheme` but coexistence with
  other types is not fully resolved)
- Delivery medium bridge (the Presentation layer in CSP model)
- Handover packaging model (structure across organizational boundaries)

## Universal overrides

Every contract file has a `notes` field for free-form content that
does not fit the schema. The skill reads these notes in subsequent
stages and can prompt the user to formalize them if they recur across
multiple projects.

This prevents the contracts from being software-only. A construction
project documenting a bridge's structural calculations can attach
industry-specific fields in the notes without forcing them into a
software-shaped schema.
