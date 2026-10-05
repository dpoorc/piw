---
id: 79
title: Add the sanitized report export
status: closed
priority: high
labels:
    - kind:feature
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

Spec #53 and ticket #66 require an optional sanitized export. It keeps
class, carrier, severity, remediation kind, and location, and strips
values and raw snippets. It is labeled as sanitized.

Add the export to `report.py`.

## Acceptance criteria

- [ ] An option writes a sanitized copy of the report.
- [ ] The sanitized copy keeps class, carrier, severity, remediation
  kind, and location.
- [ ] The sanitized copy strips values, snippets, and tags.
- [ ] The copy is labeled as sanitized.
- [ ] A test covers the sanitized export.

## Source

Spec axis. Spec #53, ticket #66.
