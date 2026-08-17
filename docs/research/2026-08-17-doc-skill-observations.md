# Doc-skill observations — handoff for the documentation-skill session

Date: 2026-08-17
Purpose: A "subagent-chat" session explored the workspace and reviewed
the documentation-skill project state. This file records observations
for the session that resumes the SKILL.md writing phase. It is not a
decision record. It flags state, risks, and drifts the resuming
session should verify.

## Project state (as of 2026-08-17)

- Contracts doc: 885 lines
  (`docs/research/2026-08-10-contracts-discovery-procedure.md`).
- Assumption rulings A1-A10 recorded and applied
  (`docs/research/2026-08-15-assumption-review.md`).
- A8 divergence unpacking: batches 1-5 and B resolved and applied
  (`docs/research/2026-08-16-divergence-unpacking.md`).
- A2 experiments complete:
  - Run 1 (persistence + silent sections, PASSED). Evidence in
    `.prototype-a2/run1/` (triage.md, requirements.md, structure.md).
  - Run 2 (interaction protocol, all 4 personas). Evidence in
    `.prototype-a2/run2/` (record.md, deliverables).
- #7 Init module design (354 lines):
  `docs/research/2026-08-17-init-module-design.md`.
- #8 Brown-field strategy (300 lines):
  `docs/research/2026-08-17-brownfield-migration-design.md`.
- Production process (the gates): `docs/research/2026-08-17-skill-production-process.md`.
- Git: master, 9 commits ahead of origin, working tree clean except
  untracked `todo.md`.

## Next step: SKILL.md writing phase

The executable product is not written. The old WIP `doc-writing`
skill (195 lines, `skills/system/doc-writing/SKILL.md`) is still the
mounted system skill. Issue #1 (wayfinder map) says it is replaced
entirely.

The biggest known risk: the cold-model test has never run. All
experiments ran contracts-open. The artifact's verification mechanism
is a fresh session, contracts-closed, model reading only the final
SKILL.md. Plan for this before drafting.

## Standing requirements (user, 2026-08-17)

1. Cryptic-reference removal. The final SKILL.md and support files
   must not carry decision-tracking references ("batch 2", "A4",
   "B5", "Option D", "TG-1"). Research docs keep them as audit trail.
   Grep-able check, gate G1.
2. Bias-neutrality review pass. Skill content leans toward
   latest-explored topics (A2 vocabulary, recent rulings). A
   structured review pass pre-ship: re-read the pre-A2 research
   (08-08, 08-09 docs), check each old finding has a home. Gate G3.

## The three gates (from the production-process doc)

- G1 Hygiene: zero decision-tracking references. Grep-able.
- G2 Cold-model: fresh session, contracts-closed, scenario set runs.
  Behavior must match contracts on exercised paths.
- G3 Neutrality: structured re-read of pre-A2 research.

Good-enough bar: G1-G3 pass, route map works cold (5 scenarios),
interaction protocol holds cold, known limits NAMED in the artifact.

## Open questions (Q1-Q4, lean noted)

- Q1 Scenario set: 5 (light route, full cycle, brown-field,
  hostile-exit, zero-budget). Enough, or add one (e.g.
  multi-speed/regulated high-stakes)? Lean: 5 is enough.
- Q2 Client in cold tests: scripted personas via minions
  (reproducible) vs user acting (realistic)? Lean: scripted, user
  debrief after.
- Q3 Artifact location: iterate in workspace, move to standalone
  repo at ship? Lean: yes.
- Q4 Draft strategy: one-pass draft v0.1, then batched user review
  (5-7 per batch)? Lean: yes.

## Compaction constraint on cold tests

Flash-tier models degrade past ~150-200k context. Cold tests must
run one scenario per fresh session, short sessions, low context.
FIXED 2026-08-17: models.json adds modelOverrides for
`accounts/fireworks/models/deepseek-v4-flash` and
`...-0731` with `contextWindow: 210000`. Compaction now triggers
at ~194k (window - 16384 default reserve) instead of ~983k.
Applied to both the repo seed (models.json) and the live config
(.pi/agent/models.json). It does not change the cold-test plan,
it makes long sessions viable.

## Minion / intercom state (matters for Q2)

- pi-intercom is the current minion rig. Slow and single-threaded.
- Minion-1 (019feb82): 13% ctx after Run 1. May need compaction
  before reuse. Not listed as active in intercom at this writing.
- Minion-2 (019feb83): was rogue mid-session, user corrected it,
  performed the Run 2 personas after correction. Idle now.
- Minion-3 (01a00c0e): 4% ctx, excellent client in Run 1. Idle.
- The user replaced intercom minion management with a subagents
  extension (@gotgenes/pi-subagents, npm package, installed and
  verified working 2026-08-17). Install: `npm:@gotgenes/pi-subagents`
  in extensions.txt. Agents defined in the repo `agents/` dir
  (mounted to the container's global agents path by piw):
  `review.md` (read-only code/doc review), `researcher.md` (web
  research with web_search tools). Built-in general-purpose,
  Explore, Plan also available.
- pi-intercom REMAINS installed, for a different purpose: one
  session may ask another session for runtime knowledge (the
  `intercom` tool). Cross-session knowledge queries are not
  something pi-subagents can do. Do not remove pi-intercom.
- This changes how cold tests would run: the subagent tool can now
  spawn the executor and client personas in-process instead of
  intercom sessions. Update Q2 accordingly.
- Lesson from the rig: patience, trust fog-fallback, do not
  nudge-repeatedly. Flash-tier "idle" contexts look frozen when
  checked infrequently.

## Drifts noticed (verify before trusting)

- roadmap.md "Completed" section stops at 2026-08-13. It shows #7
  and #8 as "unblocked" (they are now designed and committed). It
  says pi-time-awareness is "not yet installed" (live settings show
  it installed). It lists the doc-reality mismatches that are still
  live (node:22 refs, size placeholders).
- Issue tracker: #6 "in-progress" (its substance resolved via the
  contracts). #7, #8 "open" (designed, not shipped to a skill).
  The `issues` CLI exists only inside the pi Docker image.
- The mounted `doc-writing` skill is the old draft; the new skill
  does not exist yet. Do not confuse the two.
- Models: repo models.json lists fireworks `deepseek-v4` at
  contextLength 131072; the live model in use is
  `accounts/fireworks/models/deepseek-v4-flash-0731` with a 1000k
  window (from pi's registry, models-store.json). The repo models
  file does not list the live model. The compaction fix will add
  modelOverrides for it.

## Fields never exercised (candidates for the known-limits note)

From the Run 1 report and the production doc:
- taxonomy.scheme conventions other than frontmatter
- taxonomy.assignment model automatic/hybrid
- delivery media in_product / obsidian_vault
- lifecycle model continuous / event_driven / ad_hoc / none
- navigation breadcrumbs non-none
- retrieval.search=false

Gate G2's good-enough bar says known limits get a small note in the
artifact; deep validation is post-v1 in the A1 loop.

## #8 assumption zones flagged (decision pending)

- Stage C (moveability, can't-move cases) and Stage E (coexistence,
  split-brain) have no live experiment. Open question: run a
  targeted brown-field experiment, or ship flagged + post-v1
  validation. The #7/#8 design docs flag this.

## Product risk summary

1. Cold-model compression is the untested unknown. Structure the
   whole writing phase around getting to a G2 run early.
2. Fragmentation risk: do not invent a modules/ pattern; keep
   fragmentation minimal. Ground truths live IN SKILL.md.
3. The skill must be harness-agnostic (A9): no pi-specific
   dependencies in the artifact. Tool mapping stays generic.
   pi-intercom was the test rig, not the product.
4. v1 is explicitly an iteration (A1): thresholds tuned on
   simulated data are provisional. The three-case regression suite
   stays the anchor.

## Suggested first moves for the resuming session

1. Resolve Q1-Q4 (leans above; Q2 depends on which rig exists).
2. One-pass draft SKILL.md v0.1 from the contracts (per Q4 lean).
3. Run G1 hygiene grep immediately after the draft.
4. Set up the G2 cold-model run: fresh session, contracts-closed,
   5 scenarios, one scenario per session, short.
5. Run G3 neutrality pass before shipping.
6. Fix the roadmap/tracker drift as time allows.
