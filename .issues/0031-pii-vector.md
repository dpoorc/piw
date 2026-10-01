---
id: 31
title: PII vector
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 36
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

Presidio content PII detection plus the bundled checksum cross-check,
reported like secrets.

## Acceptance criteria

- [ ] Presidio is required for content PII; a missing tool stops this check.
- [ ] Detection is regime-neutral and identifiability-based.
- [ ] The confidence mapping is applied (checksum and structural validation to certain, pattern plus context to likely, bare pattern to possible).
- [ ] Metadata PII is deferred to the metadata vector.
- [ ] The fixture PII string is found.

## Blocked by

- #27 - Inventory and report skeleton
- #28 - Fixture project and seam harness
