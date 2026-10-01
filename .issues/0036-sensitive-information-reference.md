---
id: 36
title: Sensitive-information reference
status: open
priority: medium
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 37
    depends-on:
        - 30
        - 31
        - 33
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#25 - Spec: pre-publication sterilization skill

## What to build

The multi-round sensitive-information reference, built from known risks,
prior findings, and file-level judgments, and used to find more elusive
occurrences.

## Acceptance criteria

- [ ] The reference is built during the scan.
- [ ] Later rounds use it to find further occurrences.
- [ ] It is stored in the output directory, excluded from the scan, and never included in the sanitized export.
- [ ] It is optional, and the scan stops when a round adds nothing new.

## Blocked by

- #30 - Secrets vector
- #31 - PII vector
- #33 - Hygiene and doc hygiene vector
