---
id: 34
title: Licensing, attribution, and authorship vector
status: open
priority: medium
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 37
    depends-on:
        - 27
        - 28
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#25 - Spec: pre-publication sterilization skill

## What to build

The licensing, attribution, and authorship vector: license presence and
consistency, third-party notices, attribution, and the authorship
preference.

## Acceptance criteria

- [ ] A missing license is framed as a decision, not a defect.
- [ ] Declared-versus-actual mismatch and conflicting statements are flagged high.
- [ ] Flags stay high-level; deeper compliance is handed off to a compliance workflow on request.
- [ ] The authorship preference (named attribution or anonymity) is respected.
- [ ] The skill flags only; it does not author legal text.

## Blocked by

- #27 - Inventory and report skeleton
- #28 - Fixture project and seam harness
