---
id: 70
title: Hygiene and doc hygiene vector
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 73
        - 74
    depends-on:
        - 64
        - 65
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

The hygiene vector: strays, large binaries, leaky TODO-type comments,
absolute local paths, `.gitignore` gaps, extension and content mismatch,
and doc hygiene.

## Acceptance criteria

- [ ] Large-binary thresholds are 5 MB default and a 50 MB hard flag, with tracked and untracked reported separately.
- [ ] `.gitignore` findings are reported, with resilient directory and pattern suggestions.
- [ ] TODO, FIXME, and HACK comments are reported only when they carry leaky content.
- [ ] The soft filter treats a file that reads like an internal-facing document as one.
- [ ] The fixture stray artifact, non-resilient ignore entry, and tracked large file are found.

## Blocked by

- #64 - Inventory and report skeleton
- #65 - Fixture project and seam harness
