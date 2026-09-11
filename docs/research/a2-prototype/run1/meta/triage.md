# Triage record — Run 1 (Marta, sauces manufacturer)

Generated: 2026-08-16
Stage: Init (Stage 0) complete. Probe 5 (budget approval) unanswerable — recorded as fog with conservative default.

```yaml
description: "One plant, ~90 people, shelf-stable specialty sauces and dressings; private-label retail + foodservice. Food safety & quality manager (Marta) and one QA technician own documentation. Commercial eQMS adopted ~2y ago, roughly half migrated; controlled procedures split between eQMS, shared drive with inconsistent names, and floating paper versions. CCP monitoring logs, lot records, sanitation checklists still paper at the line. Training split between LMS and paper sign-offs. Core pain: cannot tell at any moment whether the operator's floor copy matches the current approved revision; days lost hunting 'the current SOP' before audits."
scale: medium
route: extended
  # medium plant (90 people), regulatory active → extended route (regulatory flag)

brownfield:
  exists: true
  volume: moderate
  format: "commercial eQMS (~half of controlled procedures), shared drive with inconsistent naming, paper versions floating, paper CCP/lot/sanitation logs at the line, LMS + paper training records"
  note: "Two-year eQMS adoption stalled at ~50% migration; old paper versions still float; migration history suggests a stalled rollout (prior-history probe at Stage 1)."

audiences:
  groups:
    - "operators on the line (largest group, most fragile; need how-to at moment of use — CCP target, sanitation step, filling spec; want it visible, short, plain language; do not want to search; some bilingual)"
    - "QA pair — manager + technician (only ones consuming the full lifecycle: drafts, approvals, revisions, training records, audit trails; read documents end to end)"
    - "BRC/GFSI auditor (~8 months out; samples hard: pick a document, trace to the floor revision, check the training record matches, check old paper did not survive; proof of control)"
    - "customer auditors (retail chains; seasonal requirements — packaging specs, allergen declarations, customer-specific forms; want to see their requirements land in the docs)"
    - "management (want a one-line status: audit-ready? documents current?; reads nothing else; plant manager barely wants that much)"
  cognitive_distance: high
  note: "Three to four distinct reading styles on one system: bilingual operator at a laminated card vs traceability-sampling auditor vs one-line-status manager vs full-lifecycle QA pair. The operator side is the piece consultants usually underestimate."

maintenance:
  project_size: 90
  doc_dedicated: 0
  doc_partial: 2   # manager approves/reviews; QA tech chases — eQMS updates, signatures, drive folders
  pattern: ad_hoc
  note: "Champion-led ad-hoc: manager is the only one who 'loses sleep over revision control'; technician good but overloaded (daily lab checks + line audits squeeze document work); compliance theater — supervisors sign SOP reviews without reading; maintenance keeps its own notes and barely touches controlled docs; nothing is enforced below management — missing signatures carry no consequence (attention problem, not malice)."

regulatory:
  active: true
  frameworks: ["GFSI/BRC Food Safety (audit in ~8 months)", "FDA 21 CFR 117 (FSMA)", "local/state inspections"]
  note: "Audit pressure is the dominant driver; FSMA preventive-controls documentation expectations; local inspection coverage; customer audit criteria change seasonally. Exact clause obligations (records, retention, training, traceability) to be distilled in Stage 1 authority discovery."

budget:
  timeline: "~8 months to GFSI/BRC audit"
  resources: "8-10 hours/month of QA manager time; one QA technician (shared with lab checks and line audits); eQMS license already in place"
  note: "Budget-approval dynamic unknown (fog): whether a decision-maker above the manager must approve tool spend or scope was asked, unanswered. Conservative default: small tool/infra spend within the manager's own signature authority; any larger spend or headcount flagged for approval in design."

culture:
  priority: afterthought
  note: "Plant level: documentation is a hurdle, not a tool — first thing to slip when line time is tight. Plant manager supportive in principle ('safety first' in meetings), no practical priority. Manager personally core, which is exactly the fragility: structure designed for the one person who cares cannot be operated by anyone else."

volatility:
  pace: moderate
  note: "Two clocks (wine/milk). Core steady: base recipes stable season to season, a handful of formula tweaks/year, supplier swaps 1-2/year but high-stakes. Fast edge: CCP parameter revisions on process/equipment change, new packaging lines, customer requirements several times/year (labeling, allergens, chain forms, audit criteria). The small fast ones are the risk — trivial-looking, nobody argues, they fall through the cracks: the operator does not hear it, the old form stays in the binder, the revision never gets marked obsolete."

# ── Fog items ──
fog:
  - "who above the QA manager must approve tool spend or scope (budget-approval probe unanswered at triage)"
  - "RESOLVED at Stage 1: eQMS validation CONFIRMED absent (never validated; 'vendor told us so'); tool_validation recorded in requirements.md; path to choose (vendor package / scoped / risk acceptance)"
  - "RESOLVED at Stage 1: bench — line leads hold shift binders/clipboards; operators carry CCP logs and sanitation checklists; QA tech refreshes binders when time allows; supervisors rogue-print new revisions; no declared binder owner"
  - "RESOLVED at Stage 1: prior history — previous QM's eQMS migration stalled at messy documents (owner left, vendor support ran out); earlier drive cleanup + naming convention worked ~1y then drifted (nobody owned it, 'Final_v2_FINAL' pattern)"
  - "NEW (decisive): no terminals at the line — operators cannot open the QMS from where they stand; paper/printed card at point of use is mandatory delivery"
  - "NEW: the point-of-use handover is the highest-leverage structural fix (swap not audited today; card register + recorded swap)"
  - "which languages the bilingual operators need the floor materials in"
  - "what the operator-side failure looks like in practice (pre-seeded by user: old form stays in binder, revision never marked obsolete)"

# ── Free-form overrides ──
notes:
  - "Emerging success criterion in the client's own words: 'whatever we do has to survive a real audit and the daily reality of the floor, or I am not interested.' Confirm and capture verbatim at Stage 1."
  - "Pre-seeded failure modes: (1) revision-freshness at point of use — current-SOP hunts before audits; (2) small fast changes falling through the cracks; (3) training-record vs floor-revision mismatch (the auditor's trace test)."
  - "Client availability: answered probes 1-4 fully, went silent on probe 5; assumptions recorded as fog above. Interaction conducted in character; presentation kept human-scale."
