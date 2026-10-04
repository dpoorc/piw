---
id: 66
title: Gated-fix protocol and destructive gate
status: in-progress
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 72
    depends-on:
        - 64
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

The report is presented, then approved fixes are applied. Low-risk
reversible fixes can be batched. Everything else is per-action.
Destructive actions get a separate confirmation that lists exactly what
is destroyed. A sanitized export can be produced on request.

## Acceptance criteria

- [ ] No mutation without approval.
- [ ] Each fix is proposed as an exact action: a command, or a patch with a diff.
- [ ] Batching applies only to low-risk reversible fixes.
- [ ] Destructive actions require a separate confirmation listing what is destroyed.
- [ ] The sanitized export strips values and raw snippets and is labeled as sanitized.

## Blocked by

- #64 - Inventory and report skeleton
