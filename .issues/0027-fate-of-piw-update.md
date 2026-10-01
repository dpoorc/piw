---
id: 27
title: Fate of piw update
status: open
priority: medium
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 30
    depends-on:
        - 21
        - 22
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

What does piw update mean once variants are gone?

Today it pulls the repo, rebuilds images, upgrades pi, and syncs extensions. Decide which of those survive, which move to the pi own commands, and what rebuilds when a layer or the manifest changes.
