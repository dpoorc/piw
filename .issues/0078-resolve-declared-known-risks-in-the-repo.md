---
id: 78
title: Resolve declared known risks in the report
status: open
priority: high
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

The report hardcodes every declared known risk as `not checked`. The
readiness line always says `0 found, 0 not found`. Spec #51 requires
each declared risk to end as found, not found, or not checked.

Match each declared risk against the findings. Report the status.

## Acceptance criteria

- [ ] Each declared risk shows found, not found, or not checked.
- [ ] The readiness line counts the found and not-found risks.
- [ ] A test covers a risk that is found and one that is not.

## Source

Spec axis. Spec #51.
