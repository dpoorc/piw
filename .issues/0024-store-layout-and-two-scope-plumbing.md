---
id: 24
title: Store layout and two scope plumbing
status: open
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 25
        - 26
    depends-on:
        - 20
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

How do the two tool scopes combine at runtime?

mise provides one writable root, MISE_DATA_DIR, plus read only shared roots, MISE_SHARED_INSTALL_DIRS. MISE_DATA_DIR is read early, so it must come from the environment rather than a config file.

Decide where the harness store and the project store live, how piw sets the environment, how project detection works, PATH order, and what happens when both scopes define the same tool.
