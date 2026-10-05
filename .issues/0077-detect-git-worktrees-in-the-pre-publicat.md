---
id: 77
title: Detect git worktrees in the pre-publication git checks
status: closed
priority: high
labels:
    - kind:bug
    - state:ready-for-agent
relations:
    related-to:
        - 75
created: "2026-10-05"
updated: "2026-10-05"
closed: "2026-10-05"
---

## Parent

#75 - Pre-publication review follow-ups

## What to build

`hygiene.py` and `metadata.py` test for a repository with
`os.path.isdir(root/.git)`. In a git worktree `.git` is a file, so the
git checks are skipped silently. `prepare_output.py` already uses
`git rev-parse --is-inside-work-tree`.

Use the git command, or accept a `.git` file.

## Acceptance criteria

- [ ] The metadata and hygiene vectors run their git checks in a
  worktree.
- [ ] A test covers the worktree case.
- [ ] Seam A passes.

## Source

Standards axis. Duplicated Code and divergence.
