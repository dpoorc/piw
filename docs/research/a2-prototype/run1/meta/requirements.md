# Requirements map — Run 1 (Marta, sauces manufacturer)

Generated: 2026-08-16
Stage: Discovery (Stage 1). Basis: triage.md (read back from file — chaining verified) + Stage 1 conversation. Client answered triage probes 1-4 and (on return) the eQMS-validation, bench, prior-history, languages, and success-criteria probes. Remaining open items recorded as unknowns. Facts below are client-confirmed; residual assumptions flagged `[assumed]`.

```yaml
# ── Audience deep-dive (multi-axis) ──
audiences:
  axes: ["role", "reading_style", "language", "access_depth"]
  entries:
    - id: ops
      axis_values:
        role: "line operator"
        reading_style: "moment-of-use, short, visual"
        language: "primarily English, some bilingual operators [assumed: Spanish]"
        access_depth: "point-of-use only"
      identity: "Largest and most fragile audience. Need the how-to at the moment of use: CCP target, sanitation step, filling spec. Want it visible, short, plain language. Do not want to search."
      needs:
        - description: "the current CCP target / limit at the moment of checking"
          format: how_to
        - description: "the current sanitation step sequence"
          format: how_to
        - description: "the current filling spec for the product being run"
          format: reference
      entry_point: "the physical line / equipment — laminated card at point of use [assumed]"
      frustrations: "old revision stays in the binder and nobody tells them; paperwork grumbled at, filled because required"
      note: "The piece consultants usually underestimate. Bilingual needs confirmed live on the floor."

    - id: qa
      axis_values:
        role: "QA manager + technician"
        reading_style: "full-lifecycle, end-to-end"
        language: "English"
        access_depth: "everything"
      identity: "Only two people consuming the full lifecycle: drafts, approvals, revisions, training records, audit trails."
      needs:
        - description: "traceability — document → floor revision → training record → audit evidence"
          format: specification
        - description: "workflow visibility — what is in draft, review, approved; signature chases"
          format: explanation
      entry_point: "the full library / eQMS dashboard"
      frustrations: "days lost hunting 'the current SOP' before audits; technician's document work squeezed by lab checks and line audits"
      note: "Champion pair — the only load-bearing execution capacity."

    - id: auditor
      axis_values:
        role: "BRC/GFSI auditor"
        reading_style: "sampling / adversarial traceability"
        language: "English"
        access_depth: "traceability evidence"
      identity: "The one Marta loses sleep over. Samples hard: pick a document, trace to floor revision, check training record matches, check old paper did not survive. Looking for proof of control."
      needs:
        - description: "one path from any controlled document to its current revision, its training record, and its point-of-use state"
          format: specification
        - description: "evidence that obsolete paper was retired"
          format: specification
      entry_point: "the controlled-document index / traceability matrix"
      frustrations: "a broken trace = a non-conformance"
      note: "Drives the first_class cross-reference requirement."

    - id: customer_auditor
      axis_values:
        role: "retail-chain auditor"
        reading_style: "requirements landing check"
        language: "English"
        access_depth: "their requirements in our docs"
      identity: "Retail chains audit us; their requirements change every season — packaging specs, allergen declarations, customer-specific forms."
      needs:
        - description: "visible linkage from chain requirements to our specs/forms"
          format: reference
      entry_point: "via QA pair, on request"
      frustrations: "seasonal requirement churn lands nowhere visible"
      note: "Fast-milk edge of the volatility clock."

    - id: mgmt
      axis_values:
        role: "plant manager / leadership"
        reading_style: "one-line status"
        language: "English"
        access_depth: "status summary only"
      identity: "Wants a status line in a meeting: audit-ready? documents current? Reads nothing else; the plant manager barely wants that much."
      needs:
        - description: "one-line document-health status (audit-readiness, currency)"
          format: explanation
      entry_point: "a summary surface (dashboard / weekly line)"
      frustrations: "gets nothing today, because there is no summary"
      note: "Retrieval surface, not a document consumer."

# ── Artifact inventory ──
artifacts:
  - description: "commercial eQMS, roughly half of controlled procedures migrated"
    location: "eQMS platform (vendor name not recalled in-house)"
    format: eQMS
    quality: maintained
    owner: "QA technician (refreshes); adoption originally owned by previous quality manager (left mid-migration)"
    note: "Adopted 2y ago, stalled at ~50% where documents got messy (old revisions, unclear owners); vendor onboarding support ran out around the same time the owner left. Validation: CONFIRMED absent — see tool_validation."
  - description: "shared drive with controlled procedures not yet migrated"
    location: "shared drive, inconsistent names"
    format: "digital share"
    quality: stale
    owner: "nobody — 'people reverted to personal folders and names like Final_v2_FINAL'"
    note: "Prior history: department-folder cleanup + naming-convention proposal worked ~1 year, then drifted when nobody owned it. Inconsistent naming is an authority_resolution problem."
  - description: "paper CCP monitoring logs"
    location: "at the line — sheet sits at the station"
    format: paper
    quality: maintained
    owner: "operators carry and fill; line leads hold shift binders; QA technician refreshes when time allows [bench confirmed]"
    note: "Line records — what the auditor will sample for the trace test. Binder ownership undeclared; swap not audited."
  - description: "paper lot records"
    location: "at the line / QA office"
    format: paper
    quality: maintained
    owner: "operators fill; line leads hold the shift clipboard; QA verifies [bench confirmed]"
    note: "Lot traceability — the effectivity anchor."
  - description: "paper sanitation checklists"
    location: "at the line"
    format: paper
    quality: maintained
    owner: "operators/sanitation crew [assumed]"
    note: "Fill-only, grumbled-at paperwork."
  - description: "training records — split between LMS and paper sign-offs"
    location: "LMS + paper files"
    format: mixed digital/paper
    quality: contradictory
    owner: "QA technician [assumed]"
    note: "Split system is a traceability hazard — auditor checks training matches floor revision."
  - description: "maintenance's own informal notes"
    location: "private, maintenance-owned"
    format: paper/oral
    quality: unknown
    owner: "maintenance crew"
    note: "Ghost pocket — deliberately outside controlled docs." 

# ── Constraints ──
constraints:
  regulatory:
    - "FDA 21 CFR 117 (FSMA) — preventive controls; records accuracy, legibility, independence, contemporaneity (117.160); training records (117.305); record retention 2 years (117.310) [gist, verify against text]"
    - "GFSI/BRCGS Food Safety Standard — document control, records, traceability testing, training, internal audit [gist, verify against current issue]"
    - "local/state inspections"
  distribution:
    - "paper at point of use (CCP logs, sanitation checklists, lot records) — MANDATORY: no terminals at the line, operators cannot open the QMS from where they stand"
    - "eQMS for controlled procedures and evidence"
    - "audit/customer-audit evidence on request"
  versioning: ["regulated — controlled copies, current-revision enforcement"]
  effectivity:
    needed: true
    axes: ["version", "date_range", "equipment_line"]   # product/recipe versions, effective date range, which line
    note: "CCP targets and filling specs differ per product and line; recipes change (a handful/year, high stakes); line-specific docs for new equipment."
  access: ["internal (full)", "point-of-use (operators)", "auditors (trace evidence)", "customer auditors (their-requirements evidence)"]
  tooling: ["eQMS [identity unknown]", "LMS", "shared drive", "paper system"]
  tool_validation:
    - tool: "commercial food-industry eQMS ('the QMS'; vendor name not recalled in-house; chosen 2y ago by previous QM + IT)"
      validated: no          # CONFIRMED 2026-08-16: no validation report exists; "the vendor told us so"
      required: true         # regulated records environment — procedure approvals + training evidence
      priority: critical     # no + required → hoisted risk: potential work-item-zero project
      note: "Never validated (no IQ/OQ/PQ, no 21 CFR 11 assessment, never requested; nobody in-house has the background). Client decision 2026-08-16: vendor call first (this month) asking for a validation package; preferred path = scoped validation of the modules an auditor touches (approvals + training evidence); fallback = documented risk acceptance if vendor pricing is unreasonable. Client will NOT write a validation plan from scratch. Softener: critical records (CCP logs, lot records) stay paper, so the gap sits over procedure history and training evidence."
  note: "The eQMS validation question and the paper-archives question are the two load-bearing risks. Validation CONFIRMED absent (client, 2026-08-16). Decisive floor constraint: NO terminals at the line — the physical card IS the interface; operators will not walk to a computer for a CCP limit; paper/printed card at point of use is mandatory."

# ── Governing requirements (authority discovery) ──
governing_requirements:
  - standard: "FDA 21 CFR Part 117 (FSMA preventive controls)"
    source: "eCFR 21 CFR Part 117 (https://www.ecfr.gov/current/title-21)"
    extract: "Records under the part must be accurate, legible, and indelible (117.160); training records documenting that personnel received required training (117.305); records retained at least 2 years after their creation (117.310)."
    gist: true
  - standard: "GFSI/BRCGS Global Food Safety Standard (current issue)"
    source: "BRCGS published standard (purchase/current issue; site copy if held)"
    extract: "Requires documented food-safety procedures, controlled documents with current-revision distribution, records for traceability exercises, training records, and internal audit programs. Exact clause numbers to be confirmed against the current issue — verify before audit."
    gist: true
  - standard: "Local/state food-safety inspection requirements"
    source: "local authority guidance"
    extract: "Inspection coverage per jurisdiction — verify applicable rules and record-retention expectations."
    gist: true
  # All gists marked imperfect per contract. Before the audit, distill from the actual
  # text (eCFR link + BRCGS issue copy). This is scheduled work, not a design blocker.

# ── Failure modes ──
failure_modes:
  - area: "point-of-use revision freshness (operators)"
    likelihood: high
    impact: critical
    priority: critical
    note: "The client's stated core pain: operator's floor copy vs approved revision; current-SOP hunts before audits; auditor trace test fails. Bench-confirmed mechanism: line leads hold binders, QA tech refreshes when time allows, supervisor rogue-prints new revisions, nobody audits whether every binder got the swap."
  - area: "small fast changes falling through cracks (CCP/customer churn)"
    likelihood: high
    impact: high
    priority: high
    note: "Client: 'the small ones are the risk... the old form stays in the binder, the revision never gets marked obsolete.'"
  - area: "training record vs floor revision mismatch"
    likelihood: medium
    impact: high
    priority: high
    note: "Auditor checks training matches floor revision; split LMS/paper system makes this fragile."
  - area: "binder swap drift (point-of-use handover)"
    likelihood: high
    impact: critical
    priority: critical
    note: "No declared binder owner; handover = 'whoever prints it and walks it to the line'; nobody audits the swap — exactly how old paper versions survive; the auditor's 'old paper did not survive' check rides on this."
  - area: "eQMS validation gap"
    likelihood: unknown
    impact: critical
    priority: critical
    note: "Unknown + required → hoisted risk. If unvalidated, a validation project unfolds over months."
  - area: "single point of failure — the champion pair"
    likelihood: medium
    impact: high
    priority: high
    note: "Two people hold everything (manager + tech); tech's time squeezed; if either leaves, the system implodes."
  - area: "shared drive naming chaos"
    likelihood: high
    impact: medium
    priority: medium
    note: "Inconsistent names → duplicate/obsolete copies; authority_resolution problem."
  - area: "bilingual access gap"
    likelihood: medium
    impact: medium
    priority: medium
    note: "Bilingual operators reading a laminated card: if the card is English-only, the moment-of-use guidance fails for them."

# ── Known unknowns ──
unknowns:
  - "eQMS vendor name (validation gap resolved: never validated; path chosen: scoped validation, risk-acceptance fallback; vendor call planned this month)"
  - "budget-approval dynamic (who must approve spend/scope; asked at triage, unanswered)"
  - "formal language map — client flagged 'no formal language map' as a gap to close; floor coverage today is English + Spanish"
  - "success criteria — RESOLVED verbatim, see notes above"

notes:
  - "Pre-seeded failure modes from triage notes 2 confirmed and expanded."
  - "If the eQMS validation gap resolves as 'unvalidated', design must hoist it as work-item-zero (before any structure work), per contract. RESOLVED 2026-08-16: gap confirmed absent-validation; work-item-zero = the scoped validation project (vendor call first)."
  - "Success criteria (verbatim, 2026-08-16): random-morning test — pick one controlled document (CCP SOP, sanitation checklist, customer-specific form) and within minutes show: the approved revision, who approved it, the people trained on the change, and proof the floor uses exactly that revision. At audit: 'the binder, the card, and the log all match the approved revision in the system. Old paper is simply not there to find.' Honesty clause: done ≠ everything in the eQMS by audit day — the control loop must be tight (current findable, old dead, training linked) for everything, wherever it lives; migration continues past the audit at a sane pace. Nightmare test: 'I stop losing days before every audit hunting for the current SOP.'"
  - "Interaction note: client answered triage probes 1-4 richly; probes 5+ went silent ~1h (some replies failed to deliver; client resends), then resumed with full answers — validation, bench, prior history, languages, success criteria. Facts above are client-confirmed."
