---
id: 68
title: PII vector
status: closed
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 73
        - 74
    depends-on:
        - 64
        - 65
created: "2026-10-01"
updated: "2026-10-05"
closed: "2026-10-05"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

Presidio content PII detection plus the bundled checksum cross-check,
reported like secrets.

## Acceptance criteria

- [ ] Presidio is required for content PII; a missing tool stops this check.
- [ ] Detection is regime-neutral and identifiability-based.
- [ ] The confidence mapping is applied (checksum and structural validation to certain, pattern plus context to likely, bare pattern to possible).
- [ ] Metadata PII is deferred to the metadata vector.
- [ ] The fixture PII string is found.

## Blocked by

- #64 - Inventory and report skeleton
- #65 - Fixture project and seam harness
