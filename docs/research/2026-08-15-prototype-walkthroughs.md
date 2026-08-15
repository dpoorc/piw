# Prototype Walkthroughs — Structure Discovery Procedure

Date: 2026-08-15
Status: Draft — pending static analysis and minion-1 review

## Method

Three scripted role-play walkthroughs of the structure discovery procedure,
executed live over pi-intercom. The session was split in two roles:

- **Skill executor** (this session): executed the Init → Discovery → Design
  stages following the contracts document as ground truth, speaking as the
  skill would. Every improvisation beyond the contracts was logged as a
  divergence.
- **Naive user** (documentation-minion-2, fresh context): played three
  personas with fixed facts and free voice — Zara (small greenfield),
  Marcus (medium brown-field), Dr. Rivera (regulated).

The user's context was kept deliberately cold: it never saw the contracts,
the framework, or any prior design work. It answered in character, could be
confused or impatient, and could refuse to be helpful.

Purpose: behavioral validation of the contracts before building the Init
module (#7) and brown-field strategy (#8). The divergence log below is the
requirements list for the SKILL.md and the seed for the known-good default.

---

## Case A — Zara (small greenfield)

**Persona:** 28, personal recipe collection (~200) + small food blog. Wants
the 2019 chili findable and a path from notes to blog posts. Low tech
comfort, one-hour time budget, no homework. No team.

### What happened

Triage flowed naturally. Zara's Q1 answer overflowed into Q2 (brownfield),
Q4 (audience), and Q7 (budget) — real conversation doesn't fit question
slots. Discovery at small scale was 4 probes, and triage/discovery visibly
blurred together. The design converged to three concrete actions — not a
schema.

**The design that emerged:**
1. Naming rule for the ~15 recipes she actually cooks (chili first), one
   habit for new ones, designed to survive lapses ("needs to survive a
   Tuesday")
2. One 10-line index file, top of the main folder, partial staleness
   explicitly accepted
3. One screenshot promote-or-delete purge (promote what you'll cook,
   delete the rest — she found this scope item herself)

Plus two boundaries she set: permission to leave the strays unfixed
(omission discipline, user-initiated), and the partner gets findability
for the chili but no system ("you don't build maintenance for people who
haven't asked for it").

### Divergences

| # | Divergence | Implication |
|---|-----------|-------------|
| A1 | Q1's answer overflowed into Q2/Q4/Q7 — sequential asking would have re-asked what she already said | The skill must probe-and-merge, not ask 9 questions verbatim. Question fatigue is a real failure mode at small scale. |
| A2 | Route said `known_good` but the default's shape was fog — had to improvise it live | The known-good default IS this case. Its shape can now be extracted (below). |
| A3 | Triage/discovery boundary blurred — no clean line between 9 questions and the "discovery" phase at small scale | The stage boundary is a model, not a script. The user should never perceive a stage transition. |
| A4 | Presenting the full YAML design schema would be absurd for this scale | The design artifact for small projects must be human-scale (3 actions, Zara's language), not the contract schema. The schema is the model; the presentation scales down. |

### Findings

- **User performs the load-bearing check themselves.** Zara rejected the
  index before I could: "I'd write it, then it'd go stale, then I'd feel
  guilty" — which forced the tiny-index solution. At small scale, the
  user IS the load-bearing check; the skill should invite self-assessment
  ("what would you actually maintain?") rather than assessing capacity
  abstractly.
- **Omission discipline emerges as a user-facing activity.** "Do I have
  permission to not fix everything?" — the framework principle became a
  concrete, user-initiated purge. Not a principle to teach; an activity
  to offer.
- **Structure fixes finding, not data quality.** The blog blocker
  (reconstruction: no measurements) is a writing habit, not an
  organization problem. The skill must draw this boundary honestly — a
  known-good default should not try to solve every problem with structure.
- **Audience handling at small scale is a boundary decision, not a
  system.** Multi-audience = per-audience findability limits, set by the
  owner, not a taxonomy.

---

## Case B — Marcus (medium brown-field)

**Persona:** lead dev, 8-engineer B2B SaaS. READMEs (mixed quality),
500-page stale Confluence, ~12 Google-Doc runbooks, dead wiki. Two hires
took six weeks each to onboard. Skeptical, half-hour budget, ~10h/mo
ongoing, quarterly releases. No regulatory.

### What happened

Skeptical opening ("I've seen two documentation initiatives die") set the
tone. The artifact inventory emerged rich (READMEs mixed-quality, Confluence
graveyard, runbooks "alive because people hit them mid-fire", dead wiki).
Audience map was multi-axis and vivid: new hires, incident engineers,
support (the orphaned need), day-to-day engineers, and "nobody, constantly."
Volatility split into two speeds. Failure ranking emerged in his own
priority order.

**The design that emerged (after his trim):**
1. Onboarding doc — one living "how the system works" explanation
2. Support home — product-behavior docs (wine-layer, near-zero maintenance)
3. Runbook trust — trimmed from per-deploy to top-five verified quarterly,
   attached to postmortems (event-driven)
4. Graveyard — archive-mark the dead half of Confluence, one afternoon

His trim discarded 25% of the proposal and made it real.

### Divergences

| # | Divergence | Implication |
|---|-----------|-------------|
| B1 | Medium scale = full discovery per contracts, but the user had 30 minutes | Discovery depth must be negotiable against the user's actual availability; the contracts' scale table is a ceiling, not a mandate. |
| B2 | Failure-mode assessment (3 tables in contracts) became a single gut question ("what would be fixed, not committee") | Asking "your gut order" produced crisis/risk/tax — richer than three structured tables. The skill should ask for the user's ordering first, structure second. |
| B3 | Two-speed volatility (wine/milk) not in the contract vocabulary | Volatility is not one number per project — a project can have a slow core and fast edges simultaneously. Candidate for the structural analysis vocabulary. |
| B4 | "What gets trimmed?" was the load-bearing check, and it worked | The design presentation MUST explicitly invite trimming — it turned a proposal into the user's plan and surfaced adoption resistance the skill predicted abstractly. |
| B5 | User predicted the adoption failure ("alive month one, dead by month three") | The culture-priority field warns of this; the user enacted it. The skill should surface the question ("what survives THIS team?") directly, not infer it. |

### Findings

- **User-derived lifecycle model.** Marcus proposed event-driven runbook
  updates ("this team learns through events, not schedules") — which is
  already `event_driven` in the contracts. Confirms the lifecycle options
  are right; also shows users can discover them if asked about *when*
  updates naturally happen.
- **Maintenance cost is the real selection criterion.** "The thing that
  maintains itself is the thing that survives" — low-maintenance-capacity
  teams naturally choose wine-layer (near-static) structures. The skill
  should surface this tradeoff explicitly: a structure's ongoing
  maintenance cost is often the deciding factor, not its elegance.
- **Success criteria should be captured.** "Week two, I'm productive" is
  the measurable outcome. The skill should capture the user's own success
  metric, not just the structure.

---

## Case C — Dr. Rivera (regulated medical device)

**Persona:** regulatory affairs lead, CGM manufacturer. ISO 13485, FDA 21
CFR 820, EU MDR. Legacy eQMS + paper + broken-naming electronic files.
Team of 2, audit in 9 months, high CAPA-driven doc churn.
Compliance-driven, correctness over speed.

### What happened

Opened with the stakes: "the auditor doesn't grade effort, they grade
evidence." The bridge from her intro (design transfer ongoing, CAPAs never
stop) was immediate. Her discovery output: five audit gaps in priority
order plus a root-cause diagnosis (accretion, no accountable inventory).
My first design was **torched with clause-level precision** — and the
corrections became the design.

**The corrections she made:**
- Document control reworked around 820.40(b)(1): controlled-copy regime
  (stamped posted copies at point of use; working materials marked
  "uncontrolled — for reference only"). "Pointing is not control."
- Role map as prerequisite for the retraining trigger; auditor probes
  completion with date+evidence, not requirement.
- Traceability matrix gains the review dimension (design input/output/
  transfer reviews) and must itself be a controlled record; verification
  entries cite released protocols.
- Inventory gets dispositions per row + must itself be a controlled
  document ("or you have built an uncontrolled document whose entire
  purpose is controlling documents").

**The probes she added (my misses):**
1. eQMS validation status (820.70(i)) — is the *system* itself validated?
2. Retrievability/retention (820.180) — "produce the DHR for lot X, two
   years back"; acquisition ≠ retrievability
3. The transition effective-date problem — records born mid-transition
   under new controls create nonconformances by the new procedure itself
4. Legacy CAPA disposition — documented risk-based assessment, not
   re-opening, not pretending

**The sequencing audit (her crowning moment):**
- Thread 2 (eQMS validation) is week-one, not month-one — it has an
  *unbounded outcome* (a 3-6 month IQ/OQ/PQ project if unvalidated)
- Evidence hygiene starts on the effective date; the matrix artifact can
  land later — "two dates must be one date"
- The retraining trigger is an attribute of the role map, not a phase —
  scheduling it invites "what do you mean, is it not in effect?"
- Sacrifice order: the spine (validation + effective date + control
  regime) never moves; thin the polish, never the spine

Final: "Passing an audit with a validated system and a thin decoration
plan beats failing it with a beautiful plan."

### Divergences

| # | Divergence | Implication |
|---|-----------|-------------|
| C1 | The `tooling` constraint field lists platforms but never probes whether the tool is itself validated | Regulated discovery must probe system/tool validation status (820.70(i)), not just inventory tools. Contract bug. |
| C2 | Present-then-invite-sequence-attack works for expert users | For domain experts, the design stage is a sequencing audit, not a structure fill-in. The skill must support the expert-user case: present, then invite sequence attack instead of trim. |
| C3 | Regulatory requirements drove the design, but the skill's vocabulary lacked clause-level knowledge | The skill must PRE-BAKE domain knowledge for regulated settings (the wayfinder premise) — the user should not have to supply every citation. This is the domain-aware-routing fog item, now concrete. |
| C4 | Effective dating and transition boundaries emerged organically from regulatory reality | Confirms effective dating as a first-class contract concern, and adds: the transition/effective-date boundary (records born before vs after) is a distinct real-world event the skill must plan for. |

### Findings

- **The expert-user case is a different interaction mode.** Zara/Marcus
  needed guided discovery + invitation to trim. Rivera needed the skill to
  *propose, then absorb a sequencing attack*. The interaction protocol
  must distinguish cooperative-exploration users from exacting-domain
  users — possibly by detecting pushback quality and switching modes.
- **The regulated machinery earns its place.** State machine, gatekeepers,
  audit trail, effective dating, Tier 3 templates — all five were load-
  bearing for Rivera, and she demanded MORE precision than the schema
  carries (controlled-copy regimes, disposition columns, review gates,
  tool validation). The schema is a floor, not a ceiling.
- **Domain knowledge is the skill's job.** Every regulatory citation came
  from the client. A documentation skill for regulated projects must bring
  the clause-level knowledge itself — this is the strongest argument yet
  for the "specialized wayfinder" premise: the skill pre-bakes domain
  knowledge so projects don't discover it from scratch.

---

## The Known-Good Default — seed (v0.1)

Extracted from Case A, shaped by the framework principles. This is the
emergent shape of the fog item that has been open longest:

**When:** triage scale = small, brownfield = none/light, culture ≠ hostile,
volatility ≠ chaotic, no regulatory.

**The default (3 concrete actions, no schema):**
1. **Naming rule on the ~15 things you actually use** — a consistent
   pattern, applied to a small subset first, designed to survive lapses
2. **One tiny index** — <20 lines, top-of-folder (the entry point your
   eyes land on), partial staleness explicitly accepted
3. **One promote-or-delete purge** — of the category of dead weight the
   project actually has (screenshots, draft pages, old exports)

**The boundaries that make it work:**
- Structure fixes finding, not data quality (the writing habit is a
  separate conversation)
- Permission to leave chaos alone (omission discipline, user-initiated)
- Audience boundaries set by the owner (findability limits per audience,
  not a system)
- Timeboxed ("a Saturday, not a lifestyle") — never presented as a project
- Human-scale presentation — the contract schema is the model, never the
  artifact

**Decision rule (to confirm with static analysis):** small scale + low
stakes + non-hostile culture + no regulatory → skip full discovery,
confirm the three-action shape with the user, iterate only if the user
asks for more. This is the `route: known_good` branch made concrete.

---

## Debrief findings (user-side UX data)

From the role-play partner's reflection, out of character.

### Forced questions / trust killers

- The volatility question ("do the categories stay stable or do you
  rethink them?") read canned at small scale — worked by luck, needs
  per-scale phrasing
- "Who actually reads this — the two new hires, obviously" answered
  itself
- The callback habit ("that line is going to stay with me," "the best
  trim conversation I've had") — once is rapport, five times is an
  applause loop a cynical client recognizes
- The recap-and-label deck (4 MOVES / 8 THREADS, "here's the plan one
  more time") — visible template; clients remember being listened to,
  not read back to
- Choreographed pushback: "now push back, you know the auditor better
  than I do" and "which do you *secretly know* you can't sustain" wrote
  the endings the personas delivered. Real pushback interrupts unprompted.

### Questions a real consultant would be punished for missing

- **Prior audit history** (regulatory): "What did the last audit find?
  Which clauses were already findings?" — first question a QA-adjacent
  consultant asks; never asked here
- **Attribution check** (brown-field): Marcus blamed docs for 6-week
  onboarding; nobody asked "what did the hires THEMSELVES say the blocker
  was?" — 40% codebase complexity vs 20% docs would change the design
- **Single point of failure** (personal archive): 200 recipes on one
  laptop, nobody asked "what if the laptop dies?" — the one catastrophic
  question for a personal collection
- **The bench** (who actually executes): "team of two" — but who owns the
  paper binders? Who is the consultant? Who does the walking? Never asked
- **The budget lever**: what number gets leadership to say yes? 10h/mo
  fixed or negotiable? Nobody priced the 12 engineer-weeks win

### The untested failure modes

The three cases were a highlight reel: cooperative, engaged clients who
understood their domains. **The process failing was never tested.** The
missing experiments: the hostile client, the disengaged client, the
zero-budget client, the client who fires you in hour two. Those would show
whether the process holds or whether the personas held it up.

---

## Contract defects found

1. **`tooling` field doesn't probe tool validation** (C1) — regulated
   discovery must ask "is the tool itself validated?" not just list tools
2. **No single-point-of-failure question** (debrief) — the discovery
   constraint scan has no "what happens if the primary storage dies?"
   probe; for personal archives this is the catastrophic question
3. **No attribution check** (debrief) — when a user attributes pain to
   docs ("onboarding is broken because docs are bad"), the skill should
   test the attribution ("what did the affected users say?"), not adopt it
4. **No prior-history probe** (debrief) — "what was tried before, and
   what did the last review/failure produce?" — absent from Init and
   Discovery; the wayfinder map's fog "has there been a previous attempt
   to reorganize?" was never operationalized
5. **Scale-aware phrasing missing** — the same question needs different
   wording at different scales (volatility at small scale reads canned)
6. **Volatility is not one number per project** (B3) — wine/milk
   two-speed; candidate vocabulary addition

## Recommendations for #7 (Init module) and #8 (brown-field)

### For #7 (Init module design)

1. **Build the interaction protocol from the divergence log.** The
   protocol is: probe-and-merge (don't re-ask what's answered), gut-first
   questions (ask the user's ordering before structure), invite trimming
   (for medium+) or sequence attack (for expert users), capture success
   metrics in the user's words.
2. **The known-good default is no longer fog.** v0.1 seed above; validate
   the decision rule with static analysis, then implement as the
   `route: known_good` branch with a three-action presentation.
3. **Add the missing discovery probes**: prior attempts, attribution
   check, single-point-of-failure, tool validation (regulated), audit
   history (regulated), the bench (who executes).
4. **Detect the interaction mode.** Cooperative-exploration vs
   exacting-domain — the phrase AND depths differ. Prototype the hostile
   and disengaged clients as follow-up experiments before finalizing.

### For #8 (brown-field strategy)

1. **The artifact inventory is the natural migration spine.** Marcus's
   runbooks-alive-because-hit-mid-fire and Rivera's accretion-without-
   inventory both show: the inventory IS the migration starting point
   (confirms the earlier design note).
2. **Two-speed migration.** Maps to the wine/milk split: decide per-layer
   whether migration is urgent (fast-decaying layers) or can wait
   (slow-stable layers). Do not migrate uniformly.
3. **The graveyard move generalizes.** Archive-mark-the-dead (not delete)
   so the living 20% becomes findable — this is the omission ladder as a
   concrete month-one move.
4. **The transition effective date generalizes.** For any brown-field
   migration: records born after date X are born under new controls;
   evidence hygiene starts immediately even if the formal artifact lands
   later. "Two dates must be one date."
5. **Attribution before action.** Confirm the docs are actually the
   bottleneck before building anything — the user's pain narrative is a
   hypothesis, not a diagnosis.

---

## Review round 1 (post-prototype, 2026-08-15)

Two independent reviews: a breadth-coverage analysis (minion-1, verified
by grep against the contracts) and a third-perspective report review
(minion-2). Both read the walkthrough report with fresh context and did
not run the role-play.

### Breadth analysis (minion-1)

All 6 report defects verified against the contracts by grep. Key
corrections: "prior" exists in the contracts only as an example Init fog
item, never operationalized as a question. The 13 divergences map 1:1 to
the report tables.

**Dead-field candidates** (no case touched them, nothing hints they
matter):

- taxonomy.assignment.model, taxonomy.management.who,
  management.review_required
- navigation.conventions.next_page, breadcrumbs
- delivery.media[].constraints.max_depth, hyperlinks
- organization.retrieval.search, interface.metadata_filtering
- lifecycle.expiry
- taxonomy.scheme.convention (frontmatter|separate_index|sidebar|database)

**Untested-but-load-bearing** (exercise gap; the SKILL.md writer must
test these):

- artifacts[].owner — field exists, but the bench probe never ran
- constraints.effectivity.axes — Case C is a CGM manufacturer; lot-level
  DHR retrieval (820.180) is exactly effectivity by serial/lot; zero
  probes ran
- organization.retrieval.interface.authority_resolution — Case C's
  broken-naming electronic files are precisely this problem
- organization.authoring[].file_tree.tree — no case produced an actual
  tree (A by design; B/C got action lists)
- taxonomy.scheme.type: faceted + facets — B/C multi-axis audiences hint
  at faceted; never confirmed
- cross_references.model: first_class — Case C's traceability matrix is
  exactly first-class typed relationships; never named
- maintenance.pattern — only 4 of 11 values exercised (zero, ad_hoc,
  dedicated, passionate_volunteer); ghost/distributed/rotational/
  community/institutional/project_is_docs/outsourced untested
- failure_modes[].likelihood/impact — the gut question (B2) replaced the
  structured assessment entirely
- **The whole file pipeline — no case wrote triage.md, requirements.md,
  or structure.md. Conversation→summary only. The docs/meta state
  machine is 100% unvalidated.**

**Defects the report missed:** (1) zero contract FILES produced — A4
covers presentation scale, not persistence; the state machine never ran.
(2) Section-level silence — taxonomy, navigation, cross_references never
fired in any case. (3) Success criteria never promoted to the defect
list; no contract field exists for the user's success metric. (4) No
value-pricing technique — the 12 engineer-weeks win was never priced.

**Decision-rule verdict: partially consistent, needs contract changes.**
"Small scale + no regulatory + culture not hostile" is consistent with
the contracts' route derivation. But: (a) "low stakes" is a new input
with no field — add it; (b) "skip full discovery" mildly contradicts
scale-aware depth — rewrite as: known_good → light discovery (~4 probes)
+ human-scale three-action presentation, structure.md still written as a
minimal record; (c) the rule resolves the contracts' longest-open fog
and belongs IN the route derivation, not beside it.

### Third-perspective review (minion-2)

**Story integrity:** the cases read scripted-to-converge. Tells: Zara
rejects the index "before I could" — the exact finding the framework
needed demonstrated; Marcus's crisis/risk/tax arrives in proposal order
with a tidy 25% trim; Case C's clause citations all come from the client,
so the walkthroughs validated the interaction protocol, not the domain
knowledge the skill is supposed to carry. No case failed.

**Known-good default v0.1: credible for Zara, overfit to her.** (a) It
assumes the pain is finding, not maintaining — a maintenance-pain user
gets nothing. (b) It assumes a solo owner — for a team of 3, staleness
becomes conflict (who owns the index?). (c) It is device-shaped — naming
rule + top-of-folder index assume files and folders; a physical
collection does not translate. (d) It presupposes the user knows the 15
— a structure-seeking user wants the whole archive navigable. The
"structure fixes finding, not data quality" boundary is honest but
quietly concedes the default cannot help the real problem at that scale.

**Divergence log reclassified:** real defects are C1, B3, defect #4
(prior-attempt). Observations, not schema defects: A1 (probe-and-merge),
A3 (stage-boundary blur), B4 (invite trimming), B5 (adoption prediction)
— process truths, unactionable as schema changes. Style preferences: A4
(schema-as-model vs artifact), B2 (gut-first ordering). Missing from the
log: success criteria — finding B calls for it, no contract field
exists, no defect logged.

**Debrief verdict: proceed with a gate.** The debrief recommends
prototyping hostile/disengaged clients before finalizing, but the next
steps only "decide," then proceed to #7/#8. The untested modes are
exactly those that determine Init quality: refusal handling, stop
conditions, zero capacity. Verdict: proceed on the happy path, but gate
the Init module's abort/refusal/handoff behavior on at least one hostile
and one zero-budget probe.

**Top 5 open questions for SKILL.md:**

1. Stop conditions — hostile, disengaged, zero-budget, firing user:
   abort? minimal plan? defer? No evidence, no contract field.
2. Session state — "probe-and-merge" needs a mechanism (a running
   answer-state map maintained between probes); the report never says
   what the skill tracks.
3. Mode detection — "detect pushback quality and switch modes" is a
   hand-wave; what observable signals trigger exacting-domain mode?
4. Known-good thresholds — concrete committed boundaries (item count,
   audience count, timeline) do not exist; the SKILL.md writer cannot
   write the branch condition.
5. Domain knowledge location — C3 concludes the skill must pre-bake
   regulatory knowledge, then offers it as an unverified premise
   ("specialized wayfinder"). SKILL.md must decide: embedded regulated
   modules, or routing to another skill? The report's strongest finding
   is its most unsettled.

### Synthesis (executor)

Both reviews converge on four results:

1. The file pipeline / state machine is the biggest unvalidated surface.
   No walkthrough ever wrote triage.md, requirements.md, or structure.md.
2. The known-good default works for the solo-finding user but needs
   committed thresholds and a boundaries table (ownership, medium,
   pain-type) to stop being Zara-shaped.
3. Hostile/disengaged/zero-budget probes are required before Init is
   final; minion-2 states it as a gate.
4. Domain knowledge location (embedded vs routed) is the strongest
   finding and the most unsettled design decision.

Differing emphasis: minion-1 tags divergences by contract coverage
(verified by grep); minion-2 judges by actionability (some divergences
are process truths, not schema changes). Both are correct for their
purpose — the SKILL.md writer needs both views: what to change (minion-1)
and what will or will not change the schema (minion-2).

---

## Next steps

1. ~~Static analysis pass~~ — done (review round above)
2. ~~Minion-1 review of this report~~ — done, plus minion-2 third-
   perspective review
3. Decide the hostile/disengaged-client follow-up experiments (open
   discussion with user)
4. Then: #7 (Init module) and #8 (brown-field) on validated ground
5. Fix the contract defects (add stakes input, known-good rule into
   route derivation, add missing probes, promote success criteria,
   decide dead-field candidates)
