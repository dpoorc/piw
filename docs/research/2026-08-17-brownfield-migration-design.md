# #8 — Brown-field Migration Strategy

Date: 2026-08-17
Status: Design draft — reviewable
Basis: ticket #8 questions, batch-1 transition effective-date
principle (mechanism resolves here), Run 1 Appendix A rollout
sequence (worked case), A2 interaction findings.

## Purpose

How the `documentation` skill handles projects with existing
documentation: history, accumulated cruft, legacy conventions,
physical artifacts, and externally immutable content. The strategy
targets gradual adoption that does not make documentation worse
during the transition.

## The problem, stated honestly

Migrations fail when they are treated as a single cutover event.
The evidence: countless planned "migrations" become abandoned
half-migrations (Marta's stalled eQMS: 50% rolled out, owner left,
vendor support ran out, paper kept floating). The failure pattern is
not lack of effort — it is *treating the migration as a project with
an end* instead of *a persistent traversal with a direction*.

A brown-field migration has four unavoidable realities:

1. It takes longer than expected (years, not months — the ticket's
   own framing).
2. Split-brain (old and new systems both live) is inevitable —
   the question is how "tight" the split is managed, not how to
   avoid it.
3. Some content cannot move: public URLs that must not break, paper
   archives, third-party-hosted pages.
4. The process itself can regress documentation — a half-migrated
   corpus is *worse* than a fully-legacy one when the old copy was
   the only copy.

## Core principles (carried from decisions)

1. **The transition effective date is the spine.** The migration
   names one date after which *records are born under the new
   controls*; records before it are legacy. This is distinct from
   per-document effective dating (project-wide process change vs
   document activation) — and the two must not drift apart: "two
   dates must be one date."
   - Mechanism (resolved here): the transition date applies to the
     *birth of new records*, not to existing content. New content
     enters the new structure from the date onward. Existing content
     migrates at its own pace, in waves, and is only "under new
     controls" when it physically lands there. This prevents the
     impossible demand of freezing legacy content on day zero.
2. **Contemporaneity holds during migration.** Records born under
   the new controls are contemporaneous (A3): made at the moment of
   the event, never backfilled. The transition date does NOT mean
   "backfill everything." It means "from this date, new records
   follow the new rules."
3. **Retirement never means deletion.** Obsolete legacy docs retain
   supersession links to replacements; old copies are stamped
   obsolete and tracked, never torn up (Run 1: binder retirement)
   — because auditors and history need to see the old thing died
   deliberately.
4. **The migration must not regress.** Every rule below exists to
   make the corpus better *at every moment*, not just at the end.
5. **Prior history is probed first.** "Has this been tried?" (Init
   prior-history probe; Marta: stalled eQMS migration, drive
   cleanup that drifted) — the skill learns what failed before and
   does not repeat it.
6. **Waves beat cutover.** Sequencing is by value + feasibility, not
   by completeness. (Run 1 Appendix A: audit-critical first, the
   rest after the audit, at a sane pace.)

## Stage A — Inventory

What exists, where, and in what form. This is the Discovery-stage
brown-field survey (Init records existence + volume; Discovery
inventories).

Inventory dimensions:

- **Corpus:** every documentation artifact — electronic files,
  paper, binders, cards, wikis, intranets, code comments, READMEs.
- **Location:** where each lives (system, drive, floor, binder).
- **Owner:** who touches it, who ghosts it (the bench probe result
  feeds this — executors, not titles).
- **Currency:** current, stale, obsolete, or unknown. (Quick
  classifier: is the timestamp/fact inside still true?)
- **Dependency:** what links to it (public URLs, cross-references,
  trained procedures).
- **Moveability:** can it move? (see Stage C.)

The inventory output is a table or index (the register — Run 1's
card register is its physical cousin). It is a *working artifact*,
updated as migration proceeds, not a one-time survey.

## Stage B — Assessment (triage the corpus)

Each inventory item gets a verdict. Three verdicts, no more:

1. **Keep** — current, valuable, must migrate into the new
   structure.
2. **Retire** — obsolete, superseded, or redundant with another
   item. (Retire = stamp + archive, never delete; supersession link
   if a replacement exists.)
3. **Leave** — not worth migrating and not worth retiring; it
   stays where it is, marked legacy (see coexistence, Stage E).

The verdict is about the *content*, not its location. A keep-verdict
document in a terrible location still migrates; a leave-verdict
document never moves.

Assessment is honest about effort: volume × verdict × moveability =
the migration sketch. This is budget input, staged per wave.

## Stage C — Moveability (the can't-move cases) — FLAGGED: assumption zone

No live experiment covered this; design is strategy-level,
validated in practice post-v1.

**Public URLs that cannot change:** the page keeps its URL forever
(broken links are the migration's worst regression). Options:
- canonical redirect (old URL → new location, link stays live);
- keep-behind-canonical (page stays put, becomes a pointer to the
  new home — the "physical point-of-use" principle applied to the
  web);
- version-banner (if it must stay, mark it legacy/dated so its
  staleness is honest).
Rule: a URL is retired only when the redirect is in place. Redirect
failure = the migration regressed (users hit dead ends).

**Paper/physical archives:** cannot be retroactively digitized as a
deliverable of THIS migration (that is a separate archival project).
They are inventory-ed, verdict-kept-or-retired as physical items, and
managed through the distribution mechanism (A1: the physical
point-of-use is first-class; register + tracked swap). A paper
artifact's "migration" is its re-issue under the new controls — the
same as Run 1's card swap.

**Third-party-hosted content:** cannot move by definition. Keep it,
treat it as a leave-verdict with a pointer, or, if it must be
controlled, re-host before migrating. Never "migrate" a third-party
page by copying it into the new system — that creates the ghost-copy
problem (two sources of truth).

## Stage D — Migration planning (waves + transition date)

### Sequencing: waves beat cutover

Waves are ordered by two axes: **value** (what unblocks work, risk,
compliance) and **feasibility** (what can move cleanly). The value
axis gets priority when the corpus is regulated or high-risk; the
feasibility axis gets priority when the corpus is large and messy.

Run 1's worked sequence (Marta, Appendix A):

- Phase 0: vendor/tool questions + register skeleton (the
  load-bearing control surface, before any content moves).
- Phase 1: audit-critical inventory (IDs + owners), first card set,
  one drill.
- Phase 2: floor mechanics (swap steps, named deputies, QA round
  cadence, status visibility).
- Phase 3: tiered training pair (FULL vs NOTIFIED-ATTESTED) — the
  activation gate (A2 field).
- Phase 4: lifecycle live in the platform (conditional: vendor
  native support decides digital vs physical layer).
- Phase 5: one-line status from same records.
- Until audit: quarterly random-morning test + pre-audit
  verification pass. Full migration continues past the audit at a
  sane pace.

The pattern to extract: **controls-early, content-later.** The
*control surface* (register, ownership, lifecycle, status) is built
first; the *content migration* follows wave by wave. Content never
leads control — migrating content into an uncontrolled space just
re-creates the legacy problem in a new location.

### The transition effective date (mechanism)

- Named at planning time, in agreement with the user (it is a
  process decision, not a structure one).
- Applies to *record birth*: from that date, new records are born
  under the new controls (naming, lifecycle, registers, taxonomy).
  Existing records migrate per-wave and become controlled on
  landing.
- One date, one meaning. It must equal the per-document
  effective-dating regime's date where they interact — "two dates
  must be one date." Drift between the transition date and document
  activation = split-brain confusion (a record born "new" but still
  living under old controls).
- The date is honest: if it slips, the migration reschedules the
  date rather than quietly continuing under two regimes.

## Stage E — Coexistence (split-brain management) — FLAGGED: assumption zone

No live experiment covered this; design is strategy-level, to be
validated by a targeted brown-field experiment or post-v1.

Split-brain is inevitable; management is about *tightness*.

- **The one-store rule:** the new structure is the single canonical
  store for anything that has migrated. Legacy copies of migrated
  content are stamped "superseded — the current item lives in [new
  location]" (retirement, not deletion). A lookup finds the pointer,
  never a stale duplicate.
- **The leave-marker:** leave-verdict content is physically marked
  (banner, folder name, register entry) as "legacy — not migrated,
  not current." The marker makes staleness visible instead of silent.
- **No dual-authoring:** a document is written in exactly one place.
  During migration, a not-yet-migrated doc is still written in the
  legacy location (its verdict decides its fate); a migrated doc is
  written only in the new store. The moment of transition for a
  document is the moment it becomes the controlled copy — after
  which the legacy copy is pointer-only.
- **The split-brain audit:** at regular intervals, the skill (or the
  owner) checks: is anything being written in both places? Are
  legacy copies being updated instead of the new store? The check is
  the drift guard (Run 1: the swap canary + verification round).
- **The coexistence deadline:** coexistence is a *phase*, not a
  state — the strategy carries a target end-state (migration
  complete, only deliberate legacy pockets remain) even though the
  timeline runs long.

## Stage F — Preventing regression (never make it worse)

Six guards:

1. **Controls first.** Never migrate content into an uncontrolled
   space.
2. **Redirects before retirements.** A URL dies only when its
   redirect lives.
3. **No ghost copies.** Nothing is copied into the new store and
   left alive in the old one. (Copy + mark-old-superseded, in one
   move, or don't copy.)
4. **Honest waves.** A partial wave is a *working intermediate*, not
   a failure — but it is marked partial, never presented as done.
5. **Contemporaneity.** No backfilling of records born before the
   transition date (A3). Migrating old records is legitimate (they
   arrive with history); *fabricating* records around the transition
   is not.
6. **The load-bearing check applies to the migration itself.** The
   team must be able to sustain the coexistence + wave cadence, or
   the plan is wrong. (Run 1: no zero-new-hours promise; setup is
   real work, sequenced to fit.)

## Stage G — Ongoing alignment (post-migration / perpetual)

- **Inventory is a living artifact.** Register updates as items
  move, retire, or appear.
- **The random-morning test persists** (Run 1): pick one document,
  verify the floor copy matches the approved revision, training
  records match, old paper is not present. Quarterly minimum.
- **The post-v1 iteration loop** (A1) governs: what the migration
  reveals is fed back to the skill.
- **Legacy pockets are deliberate.** Whatever remains (paper
  archives, frozen third-party pages) is inventoried, marked, and
  managed — not abandoned. "Retirement never means deletion" applies
  to entire pockets, not just documents.

## Boundaries (what #8 does NOT do)

- Does NOT run during Init. Init records existence/volume/prior
  history; the strategy activates in Discovery (inventory+assessment)
  and runs through Design (planning) and beyond.
- Does NOT digitize paper archives (separate project).
- Does NOT rewrite legacy content (verdicts: keep/retire/leave —
  content improvement is separate work).
- Does NOT promise a timeline it cannot name (honest pacing).
- Does NOT backfill history (contemporaneity).

## Accept/reject criteria

A good brown-field strategy:

1. Named a transition effective date with one meaning.
2. Inventoried the corpus (exists/volume/owner/currency/dependency/
   moveability).
3. Triaged everything into keep/retire/leave, with reasons.
4. Sequenced waves by value+feasibility with controls-early.
5. Handled every can't-move case (URL, paper, third-party) with a
   defined rule.
6. Named its coexistence tightness rules (one-store, leave-marker,
   no dual-authoring, split-brain audit).
7. Built the six regression guards.
8. Kept audit-visible honesty (partial waves marked partial, no
   backfill).

## Open items (flagged, not resolved)

- **The two assumption zones** (moveability Stage C, coexistence
   Stage E) are strategy-level only. A targeted brown-field
   experiment (enterprise wiki + public URLs + paper) would validate
   them before SKILL.md bakes the rules — OR they ship as flagged
   strategy with post-v1 validation (per earlier discussion).
- Whether the split-brain audit is a skill behavior or a client
   cadence item (the skill suggests it; the client runs it) — lean:
   skill suggests + provides the check, client owns the cadence.
- Archive naming / pocket-marking conventions (writing-phase detail).
- Whether "value vs feasibility" wave ordering deserves a formal
   scoring or stays judgment (lean: stays judgment, like the
   fast-forward triggers).
