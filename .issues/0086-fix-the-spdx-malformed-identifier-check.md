---
id: 86
title: Fix the SPDX malformed-identifier check
status: closed
priority: low
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

The SPDX check cannot see a malformed identifier. `SPDX_LINE_RE`
captures only `[A-Za-z0-9.+-]+`, so `SPDX_SHAPE_RE` always matches. The
malformed branch is dead. `checks.md` says a malformed identifier is
`medium`.

Capture the rest of the line, then test the shape.

## Acceptance criteria

- [ ] A malformed SPDX identifier is reported as `medium`.
- [ ] A well-formed but unknown identifier stays `low`.
- [ ] A test covers both.

## Source

Spec axis. `checks.md`, licensing section.
