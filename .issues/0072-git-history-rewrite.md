---
id: 72
title: Git history rewrite
status: closed
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 74
    depends-on:
        - 66
        - 67
created: "2026-10-01"
updated: "2026-10-05"
closed: "2026-10-05"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

The git history rewrite flow: `git-filter-repo`, backup, restore command,
post-rewrite cleanup, and re-scan.

## Acceptance criteria

- [ ] `git-filter-repo` is required, with no fallback.
- [ ] Rewrite is user-approved and never a substitute for rotation.
- [ ] A backup ref and a `git bundle` are taken, the bundle is verified, and the restore command is printed before the rewrite runs.
- [ ] All local refs are rewritten by default, nothing is pushed, and forks, clones, and host caches are called out.
- [ ] The reflog is expired, garbage collection runs, and a re-scan confirms the object is gone.

## Blocked by

- #66 - Gated-fix protocol and destructive gate
- #67 - Secrets vector
