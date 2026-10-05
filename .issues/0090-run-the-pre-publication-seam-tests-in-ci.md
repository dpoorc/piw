---
id: 90
title: Run the pre-publication seam tests in CI
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

`tests/run.sh` runs the hermetic suite. It never calls
`skills/system/pre-publication/tests/run_seam_a.py`. The seam tests run
only by hand.

Run Seam A from the suite, or from CI, with the optional tools absent.
Skip the checks that need an absent tool.

## Acceptance criteria

- [ ] CI runs Seam A.
- [ ] The run passes with gitleaks, exiftool, and presidio absent.
- [ ] The skip count is visible.

## Source

Standards axis. Test coverage.
