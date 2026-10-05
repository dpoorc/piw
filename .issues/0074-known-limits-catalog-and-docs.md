---
id: 74
title: Known limits, catalog, and docs
status: closed
priority: medium
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    depends-on:
        - 67
        - 68
        - 69
        - 70
        - 71
        - 72
        - 73
created: "2026-10-01"
updated: "2026-10-05"
closed: "2026-10-05"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

Name the known limits in the artifact, regenerate the skills catalog, and
document the skill.

## Acceptance criteria

- [ ] Known limits are named: live verification, hosted services, non-English PII, very large repos, archive and binary extraction, non-git history, Windows paths, and submodule history.
- [ ] The skills catalog is regenerated.
- [ ] The skill is documented, and the tool requirements are stated.

## Blocked by

- #67 - Secrets vector
- #68 - PII vector
- #69 - Metadata vector
- #70 - Hygiene and doc hygiene vector
- #71 - Licensing, attribution, and authorship vector
- #72 - Git history rewrite
- #73 - Sensitive-information reference
