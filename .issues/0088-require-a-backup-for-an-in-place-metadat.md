---
id: 88
title: Require a backup for an in-place metadata removal
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

Spec #55 says to require a backup for an in-place metadata edit.
`metadata.py remove --confirm-destructive` succeeds with no `--backup`.

Require `--backup` for an in-place edit. Keep `--out` as the
non-destructive path.

## Acceptance criteria

- [ ] An in-place edit without `--backup` is refused.
- [ ] An out-of-place edit needs no backup.
- [ ] A test covers the refusal.

## Source

Spec axis. Spec #55.
