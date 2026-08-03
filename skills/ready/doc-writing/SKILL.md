---
name: doc-writing
description: >
  Document a project using a consistent directory structure, file naming
  conventions, and writing style. WIP — subject to review.
---

# Doc writing

> **WIP**. This skill is a draft. It captures the documentation
> structure and conventions from one session. Review and refine
> before treating it as stable.

Use this skill when the task is to create or reorganize project
documentation. It describes a multi-directory structure, file naming
patterns, and the relationship with the STE-writing skill.

## 1. Directory structure

Place docs under a `docs/` directory at the project root.

```
docs/
├── index.md                 # Entry point with quick-link table
├── <topic>.md               # Top-level topic docs
├── architecture/            # System architecture
│   ├── overview.md
│   └── <topic>.md
├── known-issues/            # Known problems, each in its own file
│   ├── overview.md          # Summary table of all issues
│   └── <issue-name>.md
└── research/                # Investigations and findings
    └── YYYY-MM-DD-<topic>.md
```

At the project root, keep a `roadmap.md` that tracks todo items,
completed work, and deferred items.

### Who goes where

| Subdirectory | Content |
|---|---|
| `architecture/` | How the system is built, how to set it up, file inventory, machine profiles |
| `known-issues/` | Problems that exist and need tracking. One file per issue. `overview.md` has a summary table |
| `research/` | What was investigated and what was found. Date-prefixed filenames |
| root `index.md` | Entry point: quick-link table, project layout, status summary |

Do not nest deeper than three levels (`docs/subdir/file.md`).

## 2. File naming

| File type | Convention | Example |
|---|---|---|
| Entry point | `index.md` | `docs/index.md` |
| Topic doc | kebab-case | `machine-profiles.md` |
| Known issue | kebab-case | `scroll-zones.md` |
| Research note | `YYYY-MM-DD-<kebab-topic>.md` | `2026-08-01-sddm-wayland-nvidia.md` |
| Roadmap | `roadmap.md` at root | `roadmap.md` |

## 3. Writing style

Apply the [STE-writing](../ste-writing/SKILL.md) skill in STE-flavored
mode for all doc prose. Strict mode for procedures, runbooks, and
safety text.

Key rules:

- Active voice. "The helper starts weston", not "weston is started
  by the helper".
- One name for one thing. Do not call the same component by two
  different names.
- Short common words. Start (not commence), use (not utilize), help
  (not facilitate).
- No marketing or AI filler vocabulary. See the STE-writing skill
  for the full list.
- No preamble or closing remarks. Write only the requested text.

## 4. index.md structure

The entry point (`index.md`) at `docs/index.md` should contain:

1. A one-paragraph summary of the project
2. A quick-link table with Topic + Doc columns
3. The project directory layout (as a tree or table)
4. A status section with key facts (DM, GPU, upstream version)
5. A note about multi-host or pre-publication concerns

## 5. roadmap.md structure

`roadmap.md` lives at the project root, not inside `docs/`.

```
# Roadmap

## Todo
### High priority
- Item 1
### Medium priority
- Item 2
### Low priority
- Item 3
### Pre-publication
- Cleanup items before going public

## Completed
### YYYY-MM-DD session
- Item (with context and fix summary)
### Previous sessions
- ...

## Deferred
- Item 1
```

Todo items are on top. Completed and deferred are below. This lets
readers see what needs doing without scrolling through history.

Each completed item should include: what was fixed, why, and a link
to the relevant research or architecture doc.

## 6. Quick-link tables

Use a two-column table for navigation:

```
| Topic | Doc |
|---|---|
| System architecture | [architecture/overview.md](architecture/overview.md) |
| Display manager | [architecture/display-manager.md](architecture/display-manager.md) |
```

## 7. Multi-host projects

If the project runs on multiple machines:

- Document each machine in `environment.md` or
  `architecture/machine-profiles.md`
- Use a table per machine for specs
- Note which configs are shared and which are per-machine
- Add a "Before going public" note if the repo contains host details

## 8. Known issues overview

`known-issues/overview.md` should contain a summary table:

```
| Issue | Status | Doc |
|---|---|---|
| Scroll zones | Fixed | [scroll-zones.md](scroll-zones.md) |
| Browser dark theme | Open | [browser-dark-theme.md](browser-dark-theme.md) |
```

Status values: Open, Fixed, In Progress, Won't Fix.

## 9. Research notes

Research notes document what was investigated and what was found.
Use the date-prefixed format `YYYY-MM-DD-<topic>.md` so they sort
chronologically.

Each research note should answer:

- What was the problem?
- What was checked?
- What was the root cause?
- How was it fixed? (even if not fixed yet)
- Any notes for future reference

## 10. Processing a handoff into permanent docs

When a new session starts from a handoff, process the handoff into
permanent docs before beginning new work.

### Section mapping

| Handoff section | Destination | Action |
|---|---|---|
| Work done | `roadmap.md` -> Completed | One-line summary per fix, with date |
| Findings | `research/` or `known-issues/` | Root cause investigation -> dated research note. Persistent problem -> new known-issue file |
| WIP | (none, ephemeral) | Skip unless it reveals a new issue or config change |
| Roadmap suggestions | `roadmap.md` -> Todo | New items, prioritized |
| Other context | `architecture/` or `environment.md` | If it contains permanent config changes |

### Procedure

1. Read each handoff section
2. Map it to a destination using the table above
3. Write or update the destination doc
4. Archive the handoff

### When to skip

If the handoff is for context compaction alone (no new findings, no
new issues), skip processing. Use the handoff only to rebuild
session context.
