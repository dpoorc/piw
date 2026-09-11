# Structure design — Run 1 (Marta, sauces manufacturer)

Generated: 2026-08-16
Stage: Design (Stage 2). Basis: requirements.md (read back from file — chaining verified) + design analysis. This run deliberately exercised the never-before-fired sections: taxonomy (faceted), navigation conventions, cross_references (first_class), effectivity axes, template governance tier 3, lifecycle state machine.

```yaml
# ── Architecture ──
architecture: hybrid
rationale: "Diátaxis for function (operators consume how_to at point of use; QA consumes reference/specification), with a controlled-document system on top — the regulatory layer is not a reading experience, it is a traceability core. One stack, two truths: the operator sees a card, the auditor sees a chain. Hybrid keeps both without forcing one reading style on the other."

# ── Delivery ──
delivery:
  media:
    - medium: print
      constraints:
        max_depth: 2
        hyperlinks: false
        template_governed: true
    - medium: web      # eQMS-hosted controlled procedures + evidence
      constraints:
        max_depth: none
        hyperlinks: true
        template_governed: true
    - medium: regulated_submission   # audit evidence package
      constraints:
        max_depth: none
        hyperlinks: false
        template_governed: true
  note: "Operator media is print at point of use — MANDATED by the floor: no terminals at the line, operators will not walk to a computer for a CCP limit, so the physical card IS the interface (max depth 2, no links, template_governed so the card is the controlled document). Cards are bilingual — English + Spanish side by side, picture-first where possible (client, 2026-08-16). Binder rule (client pushback, resolved): the binder holds only the current full SOP, one per work area, held by the line lead; the card at the station is the numbers digest (targets, limits, escalations); both carry the same document ID + revision; the swap tick covers both in one action; anything else on the shelf is out of scope — kills the duplicate problem by rule. Retirement rule (resolved): obsolete copies are stamped OBSOLETE, quarantined into a dated envelope, counted against the swap record, retained — never torn up; the auditor sees the old revision died deliberately. Distribution is the load-bearing mechanism. Collapses rogue copying: the sanctioned channel is the only way a card reaches a station. Auditors get the evidence package via regulated_submission. Print constrains shared design: shallow hierarchy, no link-based navigation."

# ── Organization ──
organization:
  arrangement_types: ["hierarchy", "numbering_scheme", "matrix"]
  shared:
    - model: numbering_scheme
      description: "Controlled document IDs — e.g. SOP-<area>-<nnn>, CCP-<line>-<nnn>, REC-<type>-<nnn> — patch: 90 people, 2 maintainers; the numbering must be greppable, not clever. Old drive names were inconsistent; the scheme fixes the authority problem at the naming layer."
    note: "The numbering scheme is the single shared spine: authoring and retrieval both key off it."
  authoring:
    - model: file_tree
      tree:
        - eQMS/
          - controlled-procedures/
          - forms-records/
          - specs/               # customer specs, packaging, allergens
          - training/
          - audit-evidence/
        - drive-cleanup/         # migration backlog until fully in eQMS
    - model: numbering_scheme
      description: "Documents stored under their controlled ID; the ID is the filename. Removes the shared-drive naming chaos at the root."
    note: "eQMS is the authoring home; the shared drive exists only as a shrinking migration buffer with a sunset date."
  retrieval:
    views:
      - audience: ops
        arrangement: flat_set
        entry: "the physical line — laminated card per CCP/station, bilingual EN/ES picture-first"
        path: ["current card at the station", "card contains: target, limit, sanity check, when to escalate, EN + ES"]
      - audience: qa
        arrangement: numbering
        entry: "eQMS dashboard / master controlled-document index"
        path: ["all docs by ID", "workflow states (draft/review/current)", "training-record linkage"]
      - audience: auditor
        arrangement: matrix
        entry: "the traceability matrix — the auditor's one page"
        path: ["HACCP plan → CCP logs → training records → lot records → spec", "evidence that obsolete paper was retired"]
      - audience: customer_auditor
        arrangement: sequence
        entry: "their requirements → our specs/forms linkage"
        path: ["customer requirement → landed spec/form → current revision"]
      - audience: mgmt
        arrangement: flat_set
        entry: "one-line status surface"
        path: ["audit-ready?", "count of expired / missing-revision docs", "churn in the last month", "stations with stale last-verified date (round-cadence visibility)"]
    search: true
    interface:
      metadata_filtering: true     # filter by doc type, area, status, review-by date
      authority_resolution: enforced   # controlled IDs + enforced naming — the fix for inconsistent drive names
    note: "Retrieval fires the authority_resolution field for the first time: the shared drive's inconsistent naming was an exact match for 'free' authority resolution; enforced controlled IDs + enforced metadata closes the 'what is actually current' question."

  effectivity:
    model: inline
    axes: ["version", "date_range", "equipment_line"]
    default: named
    note: "CCP targets and filling specs differ per product version and line; effective date ranges matter (recipe changes are high-stakes); new equipment lines get their own line-specific docs. Inline frontmatter declares applies-to per document."

# ── Taxonomy ──
taxonomy:
  scheme:
    type: faceted
    facets:
      dimensions: ["document_type", "process_area", "product_category", "audience"]
    convention: frontmatter + separate_index
    note: "FIRST FIRE: faceted type — multi-axis audiences (role × reading style × access depth) map naturally to orthogonal facets: document_type (SOP/CCP/record/spec/training), process_area (receiving, cooking, filling, labeling, sanitation), product_category, audience. A CCP log is simultaneously a record, a filling-area doc, and an operator doc — no forced single hierarchy."
  tags: ["CCP", "sanitation", "allergen", "labeling", "lot-", "line-1..n", "customer-<chain>"]
  assignment:
    model: manual
    governance: enforced
    note: "FIRST FIRE: governance=enforced — decision rule (regulatory → enforced) fires for the first time: only QA pair assigns facet values; a document without complete facets cannot reach 'current'. This is what makes the auditor's matrix view truthful."
  management:
    who: controller_only
    review_required: true
    note: "FIRST FIRE: controller_only — QA manager governs the term list; adding/deprecating a term is a controlled change (ties to lifecycle), so the facet vocabulary cannot drift back into drive-name chaos."

# ── Template governance ──
template_governance:
  tier: 3
  note: "FIRST FIRE: tier 3 — regulated controlled documents: templates are controlled documents themselves with revision history. Applies to SOPs, CCP cards, records, specs, training records. The laminated operator card is tier 3 too — the card IS the current revision, stamped/tracked so the binder cannot hold a zombie revision. (Tier 3 is the correct tier when the auditor's trace test rides on template integrity.)"

# ── Navigation ──
navigation:
  conventions:
    cross_reference: "superseded-by links + related-doc references (see cross_references)"
    next_page: "workflow paths: SOP → its form → its training record"
    breadcrumbs: "none — operator surface is depth-2 flat; breadcrumbs would be noise on a laminated card"
    note: "FIRST FIRE for the navigation section: cross_reference via superseded-by (the marked-obsolete discipline the client said was missing), next_page for workflow chaining, breadcrumbs deliberately none for the operator medium."

# ── Cross-references ──
cross_references:
  model: first_class
  note: "FIRST FIRE: first_class — the auditor's trace test demands typed relationships, not hyperlinks in prose: HACCP plan →depends_on→ CCP logs; CCP log →traces_to→ lot records; SOP →requires→ training record; customer requirement →lands_in→ spec/form. Relationship types (depends_on, traces_to, requires, supersedes, referenced_by) get concrete definitions at implementation time per contract. The traceability matrix view renders these relationships; the auditor's 'pick a doc, trace it' flow works only because the links are structured. Inline links would not survive the random-sampling test."

# ── Lifecycle ──
lifecycle:
  model: state_machine
  review_cadence: event_driven + annual full review   # churn events (CCP/customer) trigger review; annual sweep for audit-readiness
  accountability:
    model: named_owner
    note: "Every controlled doc has a named owner (SME: QA manager, production supervisor, maintenance lead); owner is answerable for review-by dates and supersession. First explicit accountability fire."
  note: "Regulated → state machine, per decision rule. Swap trigger rule (client question, resolved 2026-08-16): when a revision activates, the QMS generates a distribution task as a step in the same record as the approval. The swap is OWNED by the line lead of the affected shift — they replace card + binder sheet at the shift change-over (including night shifts); the task rides the shift handover, not the QA technician's calendar. QA technician verifies by the start of her next QA round; a missing tick is a finding on her existing round. The swap tick is the floor's side of the transition audit trail (stations × tick; no standalone paper register). Audit-critical CCP changes schedule their effective date to a change-over or a tech-present shift — no interim where the floor runs an old number while the system says new. Floor-fit, round 2 (client fiction points, all resolved 2026-08-16): (1) MULTI-CUSTOMER PACKING LINE — customer-spec swaps ride the EXISTING changeover checklist as a numbered step; the checklist IS the effective event for those revisions; ticks are timestamped at the moment, late swaps record time + reason, backfill structurally impossible → honesty by construction (mirrors 21 CFR 117.160 contemporaneity). (2) NIGHT/WEEKEND SAUCE LINE — swap rides the WRITTEN handoff log (station, doc, rev), ticked at the swap moment; verbal handover carries nothing. (3) DOCK + SANITATION — senior receiving clerk on duty owns dock swaps (the person holding the receiving binder); shifts without a dedicated receiver use the written-handoff rule; sanitation uses a shift-designated lead or handoff log; every card-holding station gets a named executor per shift in its register entry at setup. CANARY CAVEAT: setup wave adds ALL card-holding stations (dock, sanitation) to the QA round cadence, weekly minimum; register shows last-verified date per station so round gaps are visible. TRAINING LEG (round 4, TIERED round 5, accepted): the swap tick has a pair — training evidence on the same revision — TIERED so the fastest edge does not clog: (a) FULL tier — change alters what the operator does (CCP parameters, allergen handling, sanitation method, correctable limits): training record lands BEFORE the effective moment; untrained = swap waits. (b) NOTIFIED-ATTESTED tier — label-only changes with unchanged operator action: notification + attestation on the changeover checklist, timestamped, documented; not a training event (awareness is the right burden when competence needs no change — BRC/FSMA evidence is about the work performed). Tier decision recorded per revision with rationale, so the auditor sees the judgment, not just the outcome. Evidence is a PHYSICAL one-page record per revision (LMS reference + paper sign-offs), assembled by the QA technician at approval, linked from the register — human reconciliation, no LMS integration. Swap tick + training evidence bind per revision as the audit pair: paper moved AND hands ready. Completes the client's random-morning test — all four answers live in the same record. If the swap rule decays, that is the canary; the verification round catches it before the auditor."
  states:
    - draft
    - review
    - approved
    - current
    - deprecated
    - archived
  transitions:
    draft → review:       submit_for_review
    review → draft:       request_changes
    review → approved:    approve (QA manager gatekeeper)
    approved → current:   activate (on effective date)
    current → deprecated: supersede
    current → archived:   eol_direct
    deprecated → archived: retire
  gatekeepers:
    review: ["subject_matter_expert", "QA technician"]
    approve: ["QA manager"]
    note: "QA manager single approve-gate — a deliberate single-point-of-failure tradeoff given a 2-person maintenance team; approved is a controlled change (ties to taxonomy management, numbering)."
  effective_dating:
    supported: true
    default: effective_date
    note: "FIRST FIRE: effective dating — recipe/spec changes activate on a declared effective date; new suppliers and new customer requirements land and activate on schedule, distinct from approval."
  audit_trail:
    supported: full
    note: "FIRST FIRE: full audit trail — every state transition logged with actor, action type, timestamp: draft→review→approve→activate→retire. The auditor's proof-of-control demand and 21 CFR 117's record expectations. Tool support: eQMS workflow log."
  expiry: "every controlled document carries a review-by date; expired docs automatically surface in the status line"
  supersession: "obsolete documents retain supersession links to their replacement — retirement never means deletion; old paper is stamped obsolete and tracked as retired"

# ── Load-bearing check ──
load_bearing:
  assessment: "Marginal-to-yes, on one condition: the structure must REDUCE the champion pair's chase-work, not add to it. Two people (manager + tech) at 8-10 hrs/mo can maintain this IF the numbered IDs + enforced facets + first_class trace links remove the current-SOP hunts. Honestly, per client: setup is real — IDs, named owners, first card set = a couple of months of one-time work inside her hours, zero new headcount; heavily sequenced (audit-critical first — CCP SOPs, sanitation, sampled customer specs — the rest after the audit at a sane pace). No zero-new-hours promise: recurring stays small ONLY if the swap rule is tight; the swap canary + verification round is the drift guard. The system exists to make 'the current thing' self-evident; if it ever requires more chasing, it has failed its own load test."
  risk: "The champion pair is the single point of failure — manager leaves or tech's time is fully eaten by lab work, and the controlled-doc system stalls. CONFIRMED: eQMS validation gap (never validated) — client chose scoped validation with risk-acceptance fallback, vendor call this month; still lands on the same two people to sponsor. Third risk: binder-swap drift — historically 'whoever prints it walks it'; the card register must not become another unowned thing; owner is QA technician; drift guard: register check folded into her existing line-audit rounds."
  mitigation: "Work-item-zero guard: resolve eQMS validation state BEFORE structure work. Structural machinery (enforced naming, enforced facets, supersession links) is designed so a third party could operate it after a briefing — the load does not depend on the two champions being present for every lookup."
  note: "Trim candidate: the customer-specific forms linkage (customer_auditor view) is the least load-bearing piece — keep it as a ledger, not a system."

# ── Success criteria ──
success_criteria: "survive a real audit and the daily reality of the floor"
note: "Client's own criterion (emerging; verbatim confirmation pending): the structure must pass the auditor's pick-a-doc-trace-it test AND an operator must find the current CCP target in under a minute, every day. Verify post-implementation: run one trace test end-to-end; ask one operator to find the current card."

# ── Governing requirements (cited, carried from discovery) ──
governing_requirements:
  - standard: "FDA 21 CFR Part 117 (FSMA preventive controls)"
    source: "https://www.ecfr.gov/current/title-21"
    extract: "Records accurate, legible, indelible (117.160); training records (117.305); retention 2 years (117.310)."
    gist: true
  - standard: "GFSI/BRCGS Global Food Safety Standard (current issue)"
    source: "BRCGS published standard — verify against current issue"
    extract: "Document control, controlled-document distribution, records for traceability exercises, training records, internal audits. Exact clauses to be confirmed before audit."
    gist: true
  - standard: "Local/state inspections"
    source: "local authority guidance"
    extract: "Inspection record expectations per jurisdiction — verify."
    gist: true

notes:
  - "Design-stage divergences/improvs: (1) audit_trail full + single approve-gate was a judgment call — contracts say regulated → 'full or transitions'; full chosen for 21 CFR 117.160's record expectations; the single gate is a champion-pair reality, flagged in load-bearing. (2) review_cadence: event_driven + annual — contracts' enum has no combined value; recorded in free text. (3) breadcrumbs 'none' is a first-use of a navigation value with a real reason (operator medium). (4) architecture: hybrid rather than pure Diátaxis — the regulatory/traceability layer is not a reading experience; documented in rationale."
  - "Silent sections fired in this run: taxonomy-whole (faceted, convention, assignment.governance, management.controller_only), navigation-whole (cross_reference, next_page, breadcrumbs), cross_references.model=first_class, effectivity (model/axes/default), template_governance tier 3, lifecycle state-machine fields (gatekeepers, effective_dating, audit_trail, expiry, supersession), organization.retrieval.interface.authority_resolution=enforced."
  - "Post-write updates 2026-08-16 (client returned with full answers): validation gap CONFIRMED absent → work-item-zero = scoped validation (vendor call this month; client prefers scoped-approvals-only, risk-acceptance fallback); bench + prior history resolved (requirements.md); no-terminals floor constraint makes print delivery mandatory; cards bilingual EN/ES picture-first; success_criteria replaced with verbatim client words; distribution swap (card register + recorded swap, QA-tech-owned) added as the load-bearing mechanism; lifecycle activate transition now triggers the swap."
  - "Design-review pushback (client, 2026-08-16 — five points + trigger question) → resolved: (1) swap timing — line lead owns the swap at shift change-over incl. night shifts; task rides shift handover; tech verifies on next QA round; missing tick = existing finding channel; audit-critical CCP effective dates scheduled to change-over/tech-present; (2) binder+card coexistence rule — binder = current full SOP only (one per work area, line-lead-held), card = numbers digest; same ID/rev; one swap tick covers both; (3) register is proof not process — QMS field (stations × tick) + existing line-audit round as verification; no new paper form; (4) retirement — stamped OBSOLETE, quarantined, counted vs swap record, retained; (5) honest setup wave — sequenced audit-critical-first; no zero-new-hours promise; canary = swap decay."
  - "Round-3 fiction points (client, 2026-08-16 — three breaks + canary caveat) → resolved: honest-late > fake-on-time as the tick principle (timestamped, no backfill — structurally contemporaneous); packing-line swaps ride the changeover checklist (the effective event for customer-spec revisions); night/weekend swaps ride the written handoff log only; dock owner = senior receiving clerk on duty (handoff-log fallback for shifts without a dedicated receiver); sanitation = shift-designated lead or handoff log; every card-holding station has a named per-shift executor written into its register entry at setup; setup wave extends QA round cadence to ALL card-holding stations weekly minimum; mgmt status line now shows stations with stale last-verified dates."
  - "Round-4 (accepted 2026-08-16): training leg — swap tick pairs with training evidence on the same revision; training lands BEFORE the effective moment; untrained = swap waits; activate precondition = training records for affected operators; swap tick + training record = the audit pair per revision. Client accepted the full structure: 'With the training leg added, this is the structure the work plan gets built on.' Commitments confirmed: vendor call this month; setup wave order CCP SOPs → sanitation → customer specs → rest; weekly round cadence to all card-holding stations; last-verified date in status line as plant-manager-visible evidence."
  - "Round-5 (final sequence fix, accepted 2026-08-16): Phase 3 TIERED — FULL training tier (change alters operator action: CCP params, allergen handling, sanitation method, correctable limits) vs NOTIFIED-ATTESTED tier (label-only, action unchanged: attestation on changeover checklist, timestamped, documented, not a training event); tier + rationale recorded per revision so the auditor sees the judgment and proportionality. Evidence = physical one-page training evidence record per revision (LMS ref + paper sign-offs), QA-tech-assembled at approval, register-linked — human reconciliation, no LMS integration. Vendor call gains question 2: native review-by + obsolete/quarantine support (decides digital vs physical lifecycle layer). Client confirmed sequence holds; starts vendor call + register skeleton this month."
  - "Contract fields still never exercised anywhere (candidates for the next run): taxonomy.scheme conventions other than frontmatter, taxonomy.assignment.model=automatic/hybrid, delivery media in_product/obsidian_vault, lifecycle.model continuous/event_driven/ad_hoc/none, navigation breadcrumbs non-none, retrieval.search=false."
  - "POST-RUN: client requested the implementation sequence (accepted 2026-08-16); delivered in-session and persisted below as Appendix A."

## Appendix A — Implementation sequence (client-delivered 2026-08-16)

- **Phase 0 (~2 weeks, ~3h):** vendor call with TWO questions — (1) validation package or support; (2) native support for review-by dates + obsolete/quarantine states, or manual binder work; register skeleton — index of every card-holding station × owner, blank slots written down.
- **Phase 1 (weeks 1-3):** audit-critical inventory — IDs + owners, order CCP SOPs → sanitation → customer specs; first card set; one swap drill at a scheduled changeover on the sauce-line CCP.
- **Phase 2 (weeks 3-6):** floor mechanics — changeover checklist gains the card-swap step (packing line); written handoff log gains swap line (night/weekend sauce line); dock + sanitation named deputies; blank slots closed; QA round cadence extended to all card-holding stations (weekly min); last-verified visible.
- **Phase 3 (weeks 4-8):** TIERED training pair — FULL tier (change alters operator action: CCP parameters, allergen handling, sanitation method, correctable limits): training record before effective moment, else swap waits; NOTIFIED-ATTESTED tier (label-only, action unchanged): attestation on the changeover checklist, timestamped, documented — not a training event; tier + rationale recorded per revision. Evidence: physical one-page training evidence record per revision (LMS ref + paper sign-offs), QA-tech-assembled at approval, register-linked — human reconciliation, no LMS integration.
- **Phase 4 (weeks 6-10):** lifecycle live in QMS — review-by dates, gatekeepers (manager approve, tech review), audit trail on, superseded docs stamped/quarantined/counted vs register. CONDITIONAL on vendor question 2: if the platform lacks native review-by/obsolete/quarantine states, fall back to the designed physical layer (stamped/quarantined binders + register counts) — mechanism already designed; the vendor answer only picks which layer carries the lifecycle.
- **Phase 5 (weeks 8-10):** one-line status (audit-ready, expired count, stale stations), drawn from the same records.
- **Until audit:** quarterly random-morning test; pre-audit verification pass — distill actual 21 CFR 117 + BRCGS text to clause level (gists become citations). Full eQMS migration continues past the audit at a sane pace.
