# Roadmap

## Todo

### High priority

- **Documentation skill full design** — The doc-writing skill (marked
  WIP) needs a full redesign. Wayfinder process in progress:
  - ✅ Framework refined: 5 invariants, 4 values, ~15 principles
  - ✅ Research: examples (15 domains), best practices (21 requirements),
    versioning (8-level taxonomy), industry practices (5 industries),
    generic organization methods (IA, faceted, S1000D, FRBR, OAIS, DITA)
  - ✅ Structure discovery procedure skeleton designed (ticket #6 WIP)
  - ✅ Stage contracts document written (Init + Discovery + Design, 604 lines)
  - ✅ Exploration items 1-6 resolved (see ticket #6)
  - ✅ Fix cross-stage verification table dependencies (9 gaps — see contracts doc)
  - ✅ Resolve taxonomy/cross_cutting boundary (eliminated cross_cutting section)
  - ✅ Fix lifecycle over-engineering (conditional state machine fields)
  - ✅ Trim cross-references (model only, defer relationship types)
  - ✅ Add effectivity/applicability scope model
  - ✅ Add delivery medium bridge (Presentation layer)
  - ✅ Clean up numbering scheme dual role (organization shared/authoring/retrieval groups)
  - ⬜ Init module design (ticket #7, unblocked)
  - ⬜ Brown-field migration strategy (ticket #8, unblocked)

- **Setup command / setup skill** — Implement `piw setup` and a
  companion setup skill. The command gathers facts, builds at least
  the core variant, installs packages, writes a log, then starts piw
  with a prompt to load the setup skill. The skill reads the install
  log and guides the user through the remaining setup procedure.

### Medium priority

- **Confidence statement integration** — Define a mechanism for the
  agent to flag low-confidence claims and give confidence estimates
  for research results. Criteria already discussed; needs a skill
  section, an APPEND_SYSTEM.md addition, or an STE-writing amendment.

- **Install pending packages** — `pi-time-awareness` is listed in
  `extensions.txt` but not yet installed. Run `piw install-packages`
  to activate it.

- **Rebuild core image** — `variants/core/Dockerfile` has a new
  multi-stage build for `git-issues`. Run `piw build core` to produce
  an image with the binary included.

- **Regenerate skills catalog** — `skills/catalog.md` may be stale.
  Run `piw generate-catalog` after the vendor skills submodule is
  updated.

- **Fix doc–reality mismatches** — Several documentation files have
  drifted from actual state:
  - `docs/architecture/variants.md` omits workstation variant
  - `README.md` omits workstation variant, has stale Node version
  - `docs/index.md` and `docs/architecture/variants.md` reference
    `node:22-bookworm-slim` instead of `node:24-bookworm-slim`
  - `variants/core/README.md` and `variants/devops/README.md` have
    `~XXX MB` size placeholders

### Low priority

- **Session file pruning** — 14 session files, 16MB. Three approaches
  documented in `docs/research/session-file-management.md`. Pick one
  and implement a `piw prune-sessions` subcommand or keep manual.

- **Create CONTEXT.md and docs/adr/** — Per the single-context domain
  convention (`docs/agents/domain.md`), a repo-root `CONTEXT.md` and
  `docs/adr/` directory signal to `/domain-modeling` and
  `/improve-codebase-architecture` skills that domain decisions are
  tracked. Currently neither exists.

### Pre-publication

- **Add LICENSE file** — `docs/publishing.md` notes there is no
  LICENSE at repo root for GitHub display. Pick MIT, Apache 2.0, or
  GPLv3.

- **Add CONTRIBUTING.md** — Document the alignment-before-action
  workflow so contributors understand the proposal process.

- **Set up minimal CI** — At minimum: build both variants, run
  `piw doctor`, validate JSON configs, check `extensions.txt`
  packages install without error.

- **Resolve publishing considerations** — See `docs/publishing.md`
  for the full checklist (README polish, friction points, naming).

## Completed

### 2026-08-13 session

- **All 9 Tier 1-3 gaps resolved.** The contracts document
  (`docs/research/2026-08-10-contracts-discovery-procedure.md`) received
  6 commits, growing to ~690 lines. All minion-review findings integrated:
  effectivity scope, taxonomy/cross_cutting boundary, delivery medium
  bridge, lifecycle conditional structure, cross-references trimming,
  organization shared/authoring/retrieval groups, authoring/retrieval
  enum expansions, and 7 missing verification table entries.
- **Contracts document structurally complete.** All sections are filled,
  all cross-stage dependencies verified. Estimated 85-90% complete.
  Remaining: 6 universal fog items (small-project default is highest
  priority).
- **Tickets #7 and #8 unblocked.** Both are ready to claim.

### 2026-08-11 session

- **Contracts document written and iterated** —
  `docs/research/2026-08-10-contracts-discovery-procedure.md` grew
  to 604 lines across 3 major revisions. 9 triage questions, multi-axis
  audience model, scale-aware discovery depth, organization model
  (authoring/retrieval separation), taxonomy types, lifecycle state
  machine, template governance tiers, cross-references, verification tables.

- **Two pi-intercom reviews completed** — documentation-minion-1
  (roast + second review) and documentation-minion-2 (industry practices + 
  organization methods research). Both reviewed final contracts.
  Consensus: lifecycle over-engineered, faceting belongs in taxonomy,
  delivery medium and effectivity are missing.

- **Exploration items 1-6 resolved** — Multi-axis audience, I-don't-know
  fallbacks, configuration coupling, lifecycle phases, number-as-locator
  all integrated into contracts. Items 7-8 (delivery medium, domain-aware
  routing) remain as fog.

- **Research saved** — Industry practices (53 KB, 5 industries) and
  generic organization methods (41 KB, 10 methods) saved to
  `docs/research/2026-08-10-industry-documentation-practices.md` and
  `docs/research/2026-08-11-documentation-organization-methods.md`.

### 2026-08-08 session

- **Handoff skill name collision resolved** — System handoff at
  `skills/system/handoff/SKILL.md` wins over vendor
  `productivity/handoff` due to pi's DFS loading order (system dir
  traversed first). Vendor handoff has `disable-model-invocation:
  true` so the model can never route to it automatically. No config
  changes or submodule patching needed.
  See [research/2026-08-08-handoff-processing.md](docs/research/2026-08-08-handoff-processing.md).

- **pi-time-awareness added to extensions.txt** — npm package for
  automatic time anchors (~hourly) and on-demand `time` tool. Added
  to `extensions.txt`. (Not yet installed — see Todo.)

- **git-issues integrated into core Dockerfile** — Multi-stage Go
  build in `variants/core/Dockerfile` builds and copies the
  `git-issues` binary to `/usr/local/bin/`.
  (Not yet built into image — see Todo.)

- **Local issue tracker initialized** — `.issues/` directory created
  with `git-issues init`. Agent context files created:
  `AGENTS.md`, `docs/agents/issue-tracker.md`,
  `docs/agents/triage-labels.md`, `docs/agents/domain.md`.
  (Untracked — needs explicit commit.)

- **Confidence statement design criteria discussed** — Criteria for
  when and how to surface confidence in agent output: flag
  low-confidence claims, give estimates for research, flag
  non-verifiable solutions, flag expensive verification. Left to
  agent discretion, not an absolute rule.
  (Design only — implementation is in Todo.)

### Previous sessions

- Template variant aligned with core/devops (usermod -l pi node
  pattern)
- yq arch detection in devops variant (uname -m branching instead
  of amd64)
- `--force` flag for `piw install-packages` (npm cache clean on
  force)
- `--mode` flag for permission profiles (permissive, restricted,
  readonly)
- Permission external_directory allow for config paths
- STE writing skill (auto-read via APPEND_SYSTEM.md)
- Handoff skill (system skill)
- Browser curator crash fixed (pi-web-access patch)
- Workstation variant created
- Verify-docs skill added

## Deferred

- **`--mode readonly` network restriction** — Needs reopen on demand.
- **MCP integration** — Not urgent; requires upstream MCP bridge work.
- **CodeGraph integration** — Heavy dependency; deferred until MCP
  bridge is active.
- **Context-mode (OpenClaw)** — Requires OpenClaw gateway plugin and
  Elastic-licensed dependency.
- **Sub-agent evaluation** — Three packages evaluated in
  `docs/research/tools-evaluation.md`. All deferred pending actual
  need.

## Prior session notes

The file `todo.md` at project root contains the user's design notes
for the setup command/skill. These have been integrated into the Todo
section above. `todo.md` is kept for reference but is superseded by
this file.
