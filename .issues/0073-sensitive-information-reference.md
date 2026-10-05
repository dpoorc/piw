---
id: 73
title: Sensitive-information reference
status: closed
priority: medium
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 74
    depends-on:
        - 67
        - 68
        - 70
created: "2026-10-01"
updated: "2026-10-05"
closed: "2026-10-05"
---

## Parent

#62 - Spec: pre-publication sterilization skill

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

- #67 - Secrets vector
- #68 - PII vector
- #70 - Hygiene and doc hygiene vector
