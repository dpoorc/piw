---
id: 80
title: Complete the remediation plan with forward fixes and history rewrites
status: open
priority: medium
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    related-to:
        - 75
created: "2026-10-05"
updated: "2026-10-05"
---

## Parent

#75 - Pre-publication review follow-ups

## What to build

`render_plan` emits only the rotation hand-off and the protection
additions. A `forward-fix` or `history-rewrite` finding gets no plan
entry. Spec #53 requires an ordered remediation plan.

Add the missing entries, ordered by severity.

## Acceptance criteria

- [ ] The plan lists forward fixes and history rewrites.
- [ ] The plan stays ordered by severity.
- [ ] Seam A checks a forward-fix entry.

## Source

Spec axis. Spec #53.
