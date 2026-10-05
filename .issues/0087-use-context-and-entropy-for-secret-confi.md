---
id: 87
title: Use context and entropy for secret confidence
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

`checks.md` says a provider rule with no context is `possible`.
`confidence_for` returns `likely` for every non-generic rule.

Use the rule and the context. Keep the default safe.

## Acceptance criteria

- [ ] A provider rule with no context is `possible`.
- [ ] A rule with a strong prefix and a valid shape stays `likely`.
- [ ] `checks.md` matches the code.
- [ ] Seam A passes.

## Source

Spec axis. `checks.md`, secrets section.
