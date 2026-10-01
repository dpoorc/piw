---
id: 37
title: Known limits, catalog, and docs
status: open
priority: medium
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    depends-on:
        - 30
        - 31
        - 32
        - 33
        - 34
        - 35
        - 36
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#25 - Spec: pre-publication sterilization skill

## What to build

Name the known limits in the artifact, regenerate the skills catalog, and
document the skill.

## Acceptance criteria

- [ ] Known limits are named: live verification, hosted services, non-English PII, very large repos, archive and binary extraction, non-git history, Windows paths, and submodule history.
- [ ] The skills catalog is regenerated.
- [ ] The skill is documented, and the tool requirements are stated.

## Blocked by

- #30 - Secrets vector
- #31 - PII vector
- #32 - Metadata vector
- #33 - Hygiene and doc hygiene vector
- #34 - Licensing, attribution, and authorship vector
- #35 - Git history rewrite
- #36 - Sensitive-information reference
