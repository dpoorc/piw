---
id: 23
title: Minimum base image
status: open
priority: high
labels:
    - wayfinder:task
relations:
    blocks:
        - 28
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

Fix the exact baked list, how each item is installed, and the resulting image size.

T0 and T1 are already decided in the default contents ticket. This ticket turns the list into a Dockerfile: apt package, archive, or official installer for each item, on the Debian 13 base, plus the measured size.
