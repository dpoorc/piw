---
id: 26
title: Skill package, intake, and tool check
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 27
        - 28
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#25 - Spec: pre-publication sterilization skill

## What to build

The `pre-publication` skill exists and is invocable. Running it collects
intake: public mode (default open source), declared known risks, and the
authorship preference. It checks required and optional tools and prints
install instructions for the missing ones. It creates the gitignored
output directory and excludes that path from later scans.

## Acceptance criteria

- [ ] The skill loads and is user-invoked only.
- [ ] Intake collects public mode, known risks, and authorship preference.
- [ ] Tool check reports present and absent tools with install instructions.
- [ ] The output directory is created and confirmed gitignored; if it is not, the skill proposes an ignore fix or stops.
- [ ] No scan runs before intake completes.

## Blocked by

None - can start immediately.
