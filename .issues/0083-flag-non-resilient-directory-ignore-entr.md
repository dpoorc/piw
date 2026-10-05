---
id: 83
title: Flag non-resilient directory ignore entries
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

`scan_ignore_entries` skips every entry that ends in `/`. Spec #58
lists `docs/ref/competitor-product-re/` as a bad example: a directory
ignore that names a specific directory.

Flag a directory entry that names a specific directory, and suggest a
resilient pattern.

## Acceptance criteria

- [ ] A directory ignore that names one directory is reported.
- [ ] The finding suggests a resilient pattern.
- [ ] Seam A passes.

## Source

Spec axis. Spec #58.
