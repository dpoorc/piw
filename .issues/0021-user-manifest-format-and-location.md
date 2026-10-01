---
id: 21
title: 'User manifest: format and location'
status: open
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 22
        - 26
        - 27
    depends-on:
        - 20
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

What is the single declarative file a user edits to extend the harness, what does it declare, and where does it live?

It must cover store tools, root built system packages, pi extensions, and environment variables. It must extend the baked defaults rather than replace them. It must live in a gitignored path.
