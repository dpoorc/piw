---
id: 65
title: Fixture project and seam harness
status: closed
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
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

A fixture project with planted findings, an expected-findings list, and
an automated runner that invokes the skill's scripts against it and
compares the output. This is Seam A.

## Acceptance criteria

- [ ] Fixture contains: a secret in the working tree, a secret in git history, a PII string, an image with EXIF, an Office document with an author field, a stray artifact, a non-resilient `.gitignore` entry, and a tracked large file.
- [ ] The expected-findings list is written before the runner is used.
- [ ] The runner executes the scripts against the fixture and reports pass or fail per expected finding.
- [ ] The G1 hygiene check (no decision-tracking references) runs.

## Blocked by

- #63 - Skill package, intake, and tool check
