---
id: 20
title: 'Repo shape: public content vs user state'
status: open
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 21
        - 22
        - 24
        - 29
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

How does the repo separate public upstream content from user state, so that git pull stays clean and the split is obvious?

Leading idea from the user: a single gitignored local state namespace, for example .local/, holding everything user owned. Today the untracked paths are scattered across .pi/, extensions/, and .env.

Decide the namespace, what moves into it, what stays where, whether the pi paths under .pi/ remain, and how the rule is enforced.
