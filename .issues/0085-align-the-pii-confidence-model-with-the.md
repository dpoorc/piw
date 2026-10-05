---
id: 85
title: Align the PII confidence model with the ticket
status: closed
priority: medium
labels:
    - kind:enhancement
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

Ticket #68 sets the confidence model: checksum and structural
validation to `certain`, pattern plus context to `likely`, bare pattern
to `possible`. `pii.py` returns `likely` for a structurally valid SSN
and for a bare email or phone pattern.

Align the model, or update the ticket if the model changed.

## Acceptance criteria

- [ ] A structurally valid SSN is `certain`.
- [ ] A bare email or phone pattern is `possible`.
- [ ] The checks reference matches the code.
- [ ] Seam A passes.

## Source

Spec axis. Ticket #68.
