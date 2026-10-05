---
id: 75
title: Pre-publication review follow-ups
status: open
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    related-to:
        - 76
        - 77
        - 78
        - 79
        - 80
        - 81
        - 82
        - 83
        - 84
        - 85
        - 86
        - 87
        - 88
        - 89
        - 90
created: "2026-10-05"
updated: "2026-10-05"
---

## Source

Two-axis review of the pre-publication work since `f8fb110`. The
Standards axis checks the repo's documented standards and the smell
baseline. The Spec axis checks the spec and the tickets.

## What to build

One fix per child ticket. The children are grouped below by axis.

## Standards

- #76 - Extract a shared support module.
- #77 - Detect git worktrees in the git checks.
- #90 - Run the seam tests in CI.

## Spec

- #78 - Resolve declared known risks.
- #79 - Add the sanitized report export.
- #80 - Complete the remediation plan.
- #81 - Check the reflog and hook contents.
- #82 - Check vendored license headers and provenance.
- #83 - Flag non-resilient directory ignore entries.
- #84 - Add git-filter-repo to the layer.
- #85 - Align the PII confidence model.
- #86 - Fix the SPDX malformed-identifier check.
- #87 - Use context and entropy for secret confidence.
- #88 - Require a backup for an in-place metadata removal.
- #89 - Correct the licensing severity note and the stale text.

## Not ticketed

- The `tool_check.py` optional list names Kingfisher and Titus. Spec #62
  names them as optional enhancers, so this is correct.
- Closed tickets keep the `state:ready-for-agent` label. `git-issues done`
  does not change labels. The behaviour is consistent across the repo.
- `.issues/0048` is in the review range but is a separate change, not
  scope creep of this feature.
- The `## Advice` report section is an addition needed by the metadata
  vector. It is an accepted deviation from the spec's report list.

## Acceptance criteria

- [ ] Every child ticket is closed or marked wontfix.
