---
id: 64
title: Inventory and report skeleton
status: closed
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 66
        - 67
        - 68
        - 69
        - 70
        - 71
    depends-on:
        - 63
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

Running the skill inventories content and meta layers, then writes a
structured report to the output directory. The report has the header,
skipped checks, non-findings, and readiness summary sections. No findings
yet.

## Acceptance criteria

- [ ] Inventory lists present carriers and meta layers, using extension, directory convention, and content sniffing.
- [ ] An extension or content mismatch is reported.
- [ ] The report is written to the gitignored output directory, and that directory is excluded from the scan.
- [ ] The report includes header, skipped checks, non-findings, and readiness summary.
- [ ] A skipped check is recorded as skipped.

## Blocked by

- #63 - Skill package, intake, and tool check
