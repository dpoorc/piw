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
   The skill also probes whether budget approval is a concern (is
   there a decision-maker who must approve budget or scope?).
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
    # known_good = light discovery (2-4 probes) + human-scale
    #   3-action presentation; shape selected from fallback
    #   variants by delivery medium and user skill level

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
  # pace is the central, dominant pace. Multi-speed projects (a slow
  # core, fast edges - "wine and milk") record per-layer paces in the
  # note; no extra field.
  note: "how often the project changes direction or releases; per-area paces if multi-speed"

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

- Known-good default for small/simple projects (shape seeded v0.1 from
  prototype case A; fallback variants per delivery medium to be refined)
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

**Authority discovery.** When the domain is externally governed
(regulatory, standards, industry requirements), the skill identifies
the governing documents, locates their authoritative source text, and
distills per project what they require of documentation. The skill
pre-bakes only the gist of straightforward, widely-known requirements,
always marked imperfect; serious compliance work uses the actual
regulation or standard text. Discovery records the sources and the
extract in `governing_requirements`.

**Known-good route.** When triage routed `known_good`, discovery runs
light: 2-4 targeted probes (delivery medium, user skill level, existing
docs). Shape selection keys on delivery medium and user. If light
discovery surfaces ambiguity, escalate to full discovery.

**Prior history probe.** The skill asks what was tried before: previous
attempts to organize or reorganize the documentation, and what
happened. This operationalizes the Init fog example "has there been a
previous attempt to reorganize?" into a real question. Answers inform
the design (what not to repeat) and the load-bearing check.

**The bench probe.** The skill asks who actually executes the work:
who owns the paper binders, who walks the floor, who will do the
handover. This fills `artifacts[].owner` with executors, not titles.
It is a discovery question, not a triage question.

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
  # Per-tool validation record. Relevant when regulatory.active or an
  # externally-governed domain. The skill pre-knows (gist, marked
  # imperfect) that tools performing governed work may require
  # validation; it probes and records the project's state.
  # An "no" answer with a validation requirement is a hoisted risk:
  # it has unbounded outcome (a validation project, not a checklist
  # item) and is flagged in design as potential work-item-zero.
  tool_validation:
    - tool: "platform name"
      validated: unknown | yes | no | n/a
      required: true | false   # do governing requirements demand validation?
      priority: low | medium | high | critical  # flag when no + required
      note: "validation record reference, scope of validation"
  note: "free-form on integration pain points, mandatory workflows"

# ── Governing requirements ──
# External requirements the documentation must satisfy, distilled
# from authoritative sources. Populated only when externally governed.
# See authority discovery in the process section.
governing_requirements:
  - standard: "name of the governing document"
    source: "reference or link to the authoritative text"
    extract: "what it requires of documentation (quoted or paraphrased)"
    gist: true | false
    # true = pre-baked imperfect summary (marked as such)
    # false = distilled from the actual source text

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
- How discovery interacts with regulatory modules — flow control
  (authority discovery is part of the Discovery stage, see process)
  is separate from file architecture (which module file houses the
  logic — a SKILL.md implementation concern, not a contract field).
  Flow control is resolved; file architecture stays open.
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

# ── Delivery ──
# How the documentation reaches its readers.
# Medium constrains structural choices — arrangement types, depth,
# cross-reference format. When multiple media are equally primary,
# the most restrictive medium constrains shared design choices.
# The enum is illustrative — the skill adapts to project-specific
# media and constraints not listed here (use the note field).
delivery:
  media:  # array — no primary/additional distinction
    - medium: web | pdf | print | in_product | regulated_submission | obsidian_vault
      constraints:
        max_depth: none | 1 | 2 | 3 | 4 | 5
        hyperlinks: true | false
        template_governed: true | false  # only relevant for regulated_submission
  note: "free-form on medium-specific constraints, navigation strategies per medium"

# ── Organization ──
# How documents are organized and retrieved.
# Supports shared models (used by both authoring and retrieval),
# authoring models (maintainer storage), and retrieval models
# (reader views). Six arrangement primitives: hierarchy, sequence,
# network, flat_set, matrix, numbering_scheme.
# Enums are illustrative — projects adapt (use the description field).
organization:
  arrangement_types: ["hierarchy"]
  # Which structural primitives this project uses
  
  shared:  # models used identically by both authoring and retrieval
    - model: numbering_scheme | etc
      description: "free-form — pattern, allocation, any specifics"
    note: "free-form on shared models, edge cases"
  
  authoring:  # how maintainers organize documents
    - model: file_tree
      tree:
        - docs/
          - index.md
          - tutorials/
          - how-tos/
          - reference/
          - explanation/
          - <domain-specific-sections>/
          - changelog.md
    - model: numbering_scheme | flat | sequence | network | etc
      description: "free-form — storage structure, ordering logic"
    note: "free-form on authoring workflow, version control, edge cases"
  
  retrieval:  # how users find documents
    views:
      - audience: <audience-id>
        arrangement: hierarchy | sequence | numbering | flat | network | matrix | etc
        entry: "where this audience enters"
        path: ["ordered documents or sections"]
    search: true | false
    interface:  # how users narrow results
      metadata_filtering: true | false  # filter by doc properties (date, author, status)
      authority_resolution: free | suggested | enforced  # entity name standardization in search/filter
    note: "free-form on retrieval behavior, search limitations"
  
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
# Separate from retrieval: classification is about categories,
# retrieval is about finding. A project may have rich classification
# with simple retrieval, or the reverse.
taxonomy:
  scheme:  # the classification structure itself
    type: hierarchical | faceted | thesaurus | flat_controlled | none
    # none = no classification scheme (search-only retrieval)
    facets:  # only when type = faceted
      dimensions: ["audience", "component", "status"]
    convention: frontmatter | separate_index | sidebar | database
    note: "free-form on taxonomy structure, naming conventions"
  tags: ["tag1", "tag2", "tag3"]  # the actual classification terms
  assignment:  # how terms are assigned to documents
    model: manual | automatic | hybrid
    # manual = authors assign tags explicitly
    # automatic = tags derived from document content or structure
    # hybrid = manual assignment supplemented by automation
    governance: free | recommended | enforced
    # free = anyone can assign any tag
    # recommended = guidelines exist but are not enforced
    # enforced = only authorized roles can assign tags
    note: "free-form on tag assignment workflow"
  management:  # who creates, modifies, or deprecates taxonomy terms
    who: any_author | doc_owner | controller_only
    review_required: true | false
    note: "how taxonomy terms are governed"

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
# How documents reference each other.
# The design stage only decides the model. Relationship types
# (depends_on, see_also, supersedes, describes, referenced_by)
# are defined during implementation when model = first_class.
cross_references:
  model: first_class | inline | none
  # first_class = structured cross-references with typed relationships
  # inline = within-text hyperlinks only
  # none = no cross-referencing convention
  note: "how cross-references are maintained, verified, and reported"

# ── Lifecycle ──
# How documentation changes over time.
# A state machine is the default implementation, but not a requirement.
# Projects may use continuous updates, event-driven revisions,
# ad-hoc maintenance, or no formal lifecycle at all.
# Lifecycle fields are conditional on the model — see grouping below.
lifecycle:
  # ── Core fields (always present) ──
  model: state_machine | continuous | event_driven | ad_hoc | none
  # state_machine = staged progression (draft → review → current → archived)
  # continuous = live editing with no formal stages
  # event_driven = updates triggered by specific events (release, audit)
  # ad_hoc = updates happen when someone has time
  # none = no lifecycle management (not recommended)
  review_cadence: quarterly | monthly | per_release | event_driven | none
  accountability:
    model: named_owner | team_ownership | codeowners | distributed
    note: "how accountability is assigned and enforced"
  note: "free-form on review workflow, exceptions, alternative models"

  # ── State machine fields ──
  # Only populated when model = state_machine.
  # Projects using continuous, event_driven, ad_hoc, or none skip these.
  # The defaults below are a reference — projects may customize.
  states:
    - draft       # being written, not yet reviewed
    - review      # under review by designated gatekeepers
    - approved    # reviewed and approved, awaiting effective date
    - current     # effective, published, in active use
    - deprecated  # still usable but superseded by newer content
    - archived    # historical record, no longer recommended
  transitions:
    draft → review:       submit_for_review
    review → draft:       request_changes
    review → approved:    approve (gatekeeper required)
    approved → current:   activate (on effective date)
    current → deprecated: supersede
    current → archived:   eol_direct
    deprecated → archived: retire
  gatekeepers:
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
  expiry: "every page carries a review-by date | no expiry"
  supersession: "obsolete documents retain supersession links to their replacement"

# ── Load-bearing check ──
# Can the team maintain this structure?
load_bearing:
  assessment: "can the identified team maintain this structure?"
  risk: "what breaks first if capacity drops"
  mitigation: "what can be trimmed or deferred"
  note: "free-form on structural risk"

# ── Success criteria ──
# The user's own success metric, captured in their words.
# Set at design; the skill checks against it after implementation.
success_criteria: "week two, I'm productive"
note: "free-form on how success is verified, what would prove the structure works"

# ── Governing requirements (cited) ──
# External requirements carried from discovery, with sources.
# Present only when externally governed; mirrors requirements.md.
governing_requirements:
  - standard: "name of the governing document"
    source: "reference or link"
    extract: "what it requires of documentation"
    gist: true | false

# ── Free-form overrides ──
notes:
  - "anything that does not fit the above"
```

### Key design decisions

- **The skill is a wayfinder, not a lexicon.** The skill helps a
  project find its way to documentation that works. It does not carry
  domain knowledge. For externally governed domains, authority
  discovery finds the governing documents, distills what they require
  per project, and cites the sources. Pre-baked knowledge is limited to
  the gist of straightforward requirements, always marked imperfect;
  serious compliance uses the actual regulation or standard text.
- **Known-good runs light discovery.** The known-good route does not
  skip discovery: it runs 2-4 targeted probes (delivery medium, user
  skill level, existing docs), selects among fallback shapes, and
  presents a human-scale three-action plan. Small projects can need
  different shapes: a recipe collection in folders on Windows differs
  from a maker project living on GitHub. On ambiguity, escalate to
  full discovery.
- **Success criteria are captured.** The design records the user's own
  success metric, in their words, so the skill can verify later.
- **Budget approval is probed, not priced.** The budget probe asks
  whether a decision-maker must approve budget or scope. The skill
  does not run value-pricing techniques.
- **Architecture is a recommendation, not a rule.** Diátaxis is the
  default, but the skill explains alternatives and the project chooses.
- **Organization supports shared, authoring, and retrieval model groups.**
  Models used identically by both sides go in `shared`. Models specific
  to maintainer storage go in `authoring` (array — supports multiple
  models per project). Models specific to reader discovery go in
  `retrieval`. Each group is defined independently, avoiding duplication
  while allowing divergence when needed.
- **Organization supports six arrangement types.** Hierarchy, sequence,
  network, flat_set, matrix, and numbering_scheme. A project may use
  one or more. The skill discovers which types apply during discovery.
- **Cross-cutting concerns belong under taxonomy or retrieval, not a
  separate section.** Tagging, faceting, and term governance are
  classification concerns — they belong under `taxonomy`. Metadata
  filtering and entity name resolution are retrieval interface concerns
  — they belong under `organization.retrieval.interface`. The old
  `cross_cutting` section was eliminated because it duplicated fields
  and created contradictory configurations (e.g., `taxonomy.type:
  faceted` vs `cross_cutting.faceting: false` was possible).
- **Taxonomy type distinguishes how categories relate.** Hierarchical,
  faceted (orthogonal dimensions), thesaurus (associative relationships),
  flat controlled vocabularies (no hierarchy), and `none` (search-only)
  have different properties and require different discovery questions.
- **Lifecycle management is the principle; stages are one implementation.**
  The skill offers a state machine as default (draft → review → approved →
  current → deprecated → archived) but accepts alternatives: continuous
  editing, event-driven updates, ad-hoc maintenance, or no formal lifecycle.
  Regulated projects typically need the state machine. Small projects may
  use continuous or none.
- **Template governance tiers prevent schema fatigue.** Regulated
  projects need enforced templates (Tier 3). Personal notes need none
  (Tier 0). The same contract schema supports all tiers.
- **Cross-reference relationship types are an implementation detail.**
  The design stage decides only the model (inline, first_class, none).
  If `first_class`, relationship types (depends_on, see_also, supersedes,
  describes, referenced_by) are defined during implementation based on
  actual document relationships. The old schema listed 6 typed
  relationships in the contract — this was over-engineered for the
  design phase and has been trimmed.
- **Effective dating separates approval from activation.** A document
  can be approved but not yet in effect. This handles scheduled
  deployments and regulatory transition periods.
- **Migrations declare a transition effective date.** A brown-field
  migration names the date after which records are born under the new
  controls; records before it are legacy. This is distinct from
  per-document effective dating (project-wide process change vs
  document activation) and the two must not drift apart - "two dates
  must be one date." The principle is universal; the mechanism belongs
  to the brown-field strategy.
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
- **Medium constrains arrangement type choices.** Web supports all
  arrangement types. Print restricts to sequence, numbering_scheme,
  and shallow hierarchy (≤3 levels). Regulated submissions are
  template-governed — the skill skips most discovery questions.
  When multiple media are equally primary, the most restrictive medium
  constrains the shared design.
- **Lifecycle fields are conditional on model.** Projects using
  `continuous`, `ad_hoc`, or `event_driven` fill only the core
  fields (model, review_cadence, accountability, note). State machine
  fields (states, transitions, gatekeepers, effective_dating,
  audit_trail, expiry, supersession) only apply when `model:
  state_machine`. The schema shows defaults as a reference — projects
  customize them as needed.

### Fog items

- EOL procedure specifics (what happens at end-of-life — archive,
  redirect, delete) — `archived` is in the state machine but the
  exact procedure (retention period, format migration) is not defined
- Taxonomy/tag convention details (how tags are expressed —
  frontmatter, separate index, sidebar) — the `taxonomy.scheme.convention`
  field exists but implementation patterns are not catalogued
- How to handle multiple architectures in one project (e.g., Diátaxis
  for user docs, module-based for internal API docs)
- Numbering scheme integration — how numbering schemes coexist with
  other arrangement types (now partially addressed by
  `organization.authoring.numbering_scheme`)
- Delivery medium rendering details — `delivery` section captures
  structural constraints; navigation UI, rendering, and layout are
  design or implementation concerns, not contract schema
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
| `regulatory.active` | Activates authority discovery (governing docs + source extraction) | ✅ Resolved — authority discovery is part of the Discovery process |
| `budget.timeline` | Informs discovery scope (tight deadline = skip optional questions) | ✅ Direct |
| `culture.priority` | Informs discovery depth (hostile culture → minimal recommendations) | ✅ Direct |
| `volatility.pace` | Informs discovery focus (fast churn → emphasize modularity) | ✅ Direct |

**Flow control vs file architecture (resolved 2026-08-15).** Authority
discovery runs inside the Discovery stage process (see process section).
This is flow control only. Which module file houses the logic
(modules/discovery.md, modules/compliance.md, inline in SKILL.md) is
file architecture — independent of flow control, decided when writing
the SKILL.md, not a contract concern.

### Discovery → Design

| Discovery field | Design use | Status |
|----------------|-----------|--------|
| `audiences[].needs[]` | Informs architecture choice (Diátaxis quadrant per need) | ✅ Direct mapping |
| `audiences[].entry_point` | Informs retrieval views (where each audience enters) | ✅ Updated — feeds `organization.retrieval.views[].entry` |
| `artifacts[]` | Informs migration plan, what to keep/retire | ✅ Indirect (via structure) |
| `constraints.regulatory` | Forces lifecycle stages + archival rules | ✅ Direct |
| `constraints.regulatory` | Drives template governance tier (regulated = Tier 3) | ✅ Direct |
| `constraints.versioning` | Informs lifecycle and organization authoring model | ✅ Direct |
| `constraints.distribution[]` | Each entry becomes a `delivery.media[]` item, expanded with structural constraints | ✅ Direct — now defined via `delivery` section |
| `failure_modes[].priority` | Informs load-bearing check priorities | ✅ Direct |
| `constraints.effectivity.needed` | Drives `organization.effectivity.model` (needed=true → inline or separate; needed=false → none) | ✅ New — direct |
| `constraints.effectivity.axes` | Drives `organization.effectivity.axes` | ✅ New — direct |
| `audiences[].axes[]` | Hints `taxonomy.scheme.type` (multi-axis → faceted; single-axis → hierarchical) | ⚠️ Indirect — add decision rule |
| `constraints.regulatory` | Drives `taxonomy.assignment.governance` (regulated → enforced) | ⚠️ Missing — add |
| `constraints.regulatory` | Drives `lifecycle.effective_dating.supported` (regulated → true) | ⚠️ Missing — add |
| `constraints.regulatory` | Drives `lifecycle.audit_trail.supported` (regulated → full or transitions) | ⚠️ Missing — add |
| `unknowns` | Becomes fog items for the project | ✅ Direct |

### Init → Design

| Init field | Design use | Status |
|-----------|-----------|--------|
| `scale` | Complexity of file tree + drives `authoring.model` (small → flat; large → file_tree) | ⚠️ Partially missing — add authoring.model rule |
| `maintenance.pattern` | Load-bearing check | ✅ Direct |
| `maintenance.project_size` | Load-bearing check | ✅ Direct |
| `route` | Whether to run full design or offer known-good default | ✅ Direct |
| `budget.timeline` | Influences load-bearing check (tight deadline = trim scope) | ✅ Direct |
| `budget.resources` | Influences template governance tier (no budget = Tier 0 or 1) | ✅ Direct |
| `culture.priority` | Influences load-bearing check (afterthought = trim scope) | ✅ Direct |
| `volatility.pace` | Influences architecture choice (high churn = modular) | ✅ Direct |
| `volatility.pace` | Influences organization arrangement types (high churn → hierarchy + search, stable → numbering_scheme) | ✅ Direct |
| `volatility.pace` | Drives `lifecycle.model` (churn → continuous; stable → state_machine) | ⚠️ Missing — add |
| `culture.priority` | Drives `template_governance.tier` (hostile/afterthought → Tier 0; core → budget-dependent) | ⚠️ Missing — add |

---

## Project fog (dynamic, project-specific)

Each project accumulates fog items as the stages run. These are
recorded in the respective contract files and persist across sessions.

Universal fog items (apply to all projects, may never resolve):

- Known-good default (seeded v0.1 from prototype case A; fallback
  variants per delivery medium to be refined)
- Knowledge merging mechanism (reconciling contradictory artifacts)
- Regulatory interaction — flow control (authority discovery is part
  of the Discovery process) is resolved 2026-08-15; file architecture
  (which module file houses the logic) stays open, it is a SKILL.md
  implementation concern. Pre-baked gist only, always marked imperfect
- Numbering scheme integration (now partially addressed by
  `organization.authoring.numbering_scheme` but coexistence with
  other types is not fully resolved)
- Delivery medium rendering details — `delivery` section captures
  structural constraints; rendering is downstream
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
