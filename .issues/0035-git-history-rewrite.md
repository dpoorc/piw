---
id: 35
title: Git history rewrite
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 37
    depends-on:
        - 29
        - 30
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#25 - Spec: pre-publication sterilization skill

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

- #29 - Gated-fix protocol and destructive gate
- #30 - Secrets vector
