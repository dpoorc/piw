---
id: 84
title: Add git-filter-repo to the pre-publish layer
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

Spec #62 requires the container to carry gitleaks, presidio, and
git-filter-repo. The pre-publish layer carries gitleaks and presidio.
Add git-filter-repo.

## Acceptance criteria

- [ ] The pre-publish layer carries git-filter-repo.
- [ ] The layer test checks it.
- [ ] `tool_check.py` points at the layer.

## Source

Spec axis. Spec #62.
