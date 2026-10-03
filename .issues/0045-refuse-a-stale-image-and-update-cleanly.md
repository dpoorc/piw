---
id: 45
title: Refuse a stale image and update cleanly
status: closed
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    depends-on:
        - 44
created: "2026-10-03"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Fate of piw update**, as amended by **Default extensions**.

## What to build

A launch that would use a stale image refuses and says so, rather than silently using the old one or silently rebuilding. The check costs nothing extra: launch already inspects the image, and the decision is a hash of the build plan compared against a label written at build time. No stamp file exists to fall out of sync.

Updating is four steps: pull the harness, report drift, rebuild, and update pi in the container. A divergent pull fails loudly rather than merging. Drift is reported as a diff so an established user sees a newly added default.

A shipped layer is copied and owned. Because a copy has no history, an origin stamp records what the shipped layer was when it was adopted, and updating refuses to clobber local edits: it applies the update when the copy is untouched, and shows the diff and names the override when it is not. A layer that was not adopted by piw is not guessed at.

## Acceptance criteria

- [ ] Launching with a stale image refuses, naming the reason, and never rebuilds
- [ ] The staleness check needs no Docker call beyond the inspect that launch already makes
- [ ] No stamp file records image state; the image label is the single source
- [ ] Updating pulls, reports drift, rebuilds, and updates pi, and a divergent pull fails loudly
- [ ] Drift is reported as a diff by both `doctor` and `update`
- [ ] A shipped layer adopts cleanly, and updating it applies when untouched and refuses when edited
- [ ] A layer with no origin stamp is reported, not guessed at

## Blocked by

- #44 Populate the store and settle the command set
