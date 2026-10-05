---
id: 82
title: Check vendored license headers and provenance
status: open
priority: medium
labels:
    - kind:enhancement
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

Spec #59 lists stripped license headers in vendored files and missing
credits or provenance. The vector checks only directory-level license
and notice presence.

Check the first lines of vendored source files for a license or
copyright header. Report a stripped header.

## Acceptance criteria

- [ ] A vendored source file with no license header is reported.
- [ ] The fixture covers it.
- [ ] Seam A passes.

## Source

Spec axis. Spec #59.
