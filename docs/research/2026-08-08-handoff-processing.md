# Handoff Processing — Design Decisions

This note captures the design decisions from the 2026-08-08 session.
It is the permanent record that replaces the ephemeral handoff
document (`piw-handoff-2026-08-08.md`, now archived).

---

## 1. Handoff Skill Name Collision Resolution

**Problem:** Two skills named `handoff` existed in the harness:
- `skills/system/handoff/SKILL.md` (system, part of piw)
- `skills/vendor/mattpocock/skills/productivity/handoff/SKILL.md` (vendor)

Pi's skill loader discovers skills by SKILL.md files across multiple
directories. A name collision means one skill overwrites the other in
pi's registry. Which one wins depends on loading order.

**Checked:**
- Vendor handoff has `disable-model-invocation: true` — model can
  never route to it automatically. But model-activated skills don't
  need routing; they just need the right description to match.
- System handoff has `disable-model-invocation: false` (default).
- Pi's skill loading was tested empirically — DFS traversal order
  was confirmed: system directory found first, vendor second.

**Resolution:** System handoff wins because pi's DFS traverses the
system skills directory before the vendor directory. The vendor skill
has `disable-model-invocation: true` so the model never routes to it,
but even if it didn't, the collision is resolved by directory order.

**Files affected:**
- `skills/system/handoff/SKILL.md` — renamed back from `piw-handoff`
  (no actual rename, just the skill name in frontmatter)
- No config changes, no submodule patching needed.

**Fragility:** This resolution depends on pi's DFS loading order.
If pi changes its skill discovery algorithm (e.g., to use a manifest
file instead of directory traversal), the collision could re-emerge.
A more robust solution would be to rename one of the skills to avoid
the collision entirely (e.g., `piw-handoff` for the system one).

---

## 2. Triage Label Convention

**Problem:** Engineering skills reference five canonical triage roles
(bug, enhancement, needs-triage, needs-info, ready-for-agent,
ready-for-human, wontfix). The harness needs a local label vocabulary
that maps 1-to-1 with these roles.

**Resolution:** Use `<kind>:<value>` / `<state>:<value>` format.
Every issue carries exactly one `kind:` label and one `state:` label.

| Canonical role | Local label |
|---|---|
| bug | `kind:bug` |
| enhancement | `kind:enhancement` |
| needs-triage | `state:needs-triage` |
| needs-info | `state:needs-info` |
| ready-for-agent | `state:ready-for-agent` |
| ready-for-human | `state:ready-for-human` |
| wontfix | `state:wontfix` |

This separates category (kind) from workflow state (state) into two
namespaced labels. The triage skill's rule is "one category + one
state per issue" — this convention supports that directly.

**Files created:**
- `docs/agents/triage-labels.md` — canonical-to-local mapping
- `.issues/.config.yml` — label list seeded with initial values

---

## 3. Local Issue Tracker Choice

**Problem:** The engineering skills (setup-matt-pocock-skills) need
to know which issue tracker this project uses. Multiple options exist:
git-issues (local markdown), GitHub, GitLab, Jira, ClickUp,
Forgejo/Gitea.

**Resolution:** Use `git-issues` as the local file-based tracker.
It is pre-installed in the core Docker image (multi-stage Go build).
The `.issues/` directory uses the standard git-issues schema: one
Markdown file per issue with YAML frontmatter.

**Not a lock-in:** The setup skill supports alternative trackers.
git-issues is the default for this project because:
- Zero network dependencies — all issue data is local markdown
- Version-controlled alongside the code
- No API keys or service accounts needed
- Compatible with git worktrees (new issues only on main)

**Files created:**
- `.issues/` — git-issues database (`.agent.md`, `.config.yml`)
- `docs/agents/issue-tracker.md` — git-issues CLI reference and
  conventions

**Notes for future:**
- The `.agent.md` contains `git-issues agent context` — agent-facing
  documentation for the issue tracker CLI.
- Import scripts exist for GitHub migration (documented in
  `.agent.md`).

---

## 4. pi-time-awareness Integration

**Problem:** The harness lacked automatic time anchors. The agent had
no reliable way to know the current time unless the user explicitly
mentioned it or a tool was invoked.

**Checked:** Existing pi packages with time-awareness features.
Found `npm:pi-time-awareness` by EnderLiquid.

**Resolution:** Added to `extensions.txt`. The package provides:
- Automatic time anchor messages every ~1 hour (`[time]`)
- `time` tool for on-demand precision calls

No custom extension needed — the npm package handles both mechanisms.

**Status:** Listed in `extensions.txt` but not yet installed in the
container. Run `piw install-packages` to activate.

---

## 5. Documentation Architecture Overhaul (Deferred)

**Context:** The doc-writing skill (`skills/system/doc-writing/SKILL.md`)
is marked WIP and carries conventions that do not match the project's
actual structure. The handoff recommended a full redesign via wayfinder.

**Key gaps identified in the current doc-writing skill:**
- Prescribes `roadmap.md` at project root — now created by this
  processing.
- Prescribes `docs/known-issues/` with `overview.md` — the lone
  known issue lives at `docs/research/known-issues.md` instead.
- Prescribes a handoff-processing procedure — tested successfully
  during this processing session.

**Current recommendation:** The wayfinder session should:
1. Review the processing just done — what worked, what felt awkward.
2. Define the canonical doc structure for piw and its child projects.
3. Decide whether conventions should differ for the harness itself
   vs. projects it manages.
4. Consider whether research notes and known issues should merge or
   stay separate.

---

## Future Reference Notes

- The handoff file (`piw-handoff-2026-08-08.md`) is gitignored
  (`.gitignore` has `piw-handoff-*.md` pattern). Delete it after
  this processing is confirmed.
- This research note and `roadmap.md` are tracked files. Commit them
  when ready.
- The `todo.md` file at project root (untracked) contains the user's
  working notes on the setup command/skill design. It has been
  integrated into `roadmap.md` but is kept for reference.
- The handoff SKILL.md was edited by the user after the initial
  rewrite. Verify its current state before making further changes.
