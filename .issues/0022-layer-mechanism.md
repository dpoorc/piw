---
id: 22
title: Layer mechanism
status: open
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 26
        - 27
        - 28
    depends-on:
        - 20
        - 21
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

How is a user layer declared and applied?

The prior art agrees that the privileged step belongs in a build step, not at runtime. devcontainer Features use a directory with a manifest and an install.sh run as root during the build. BlueBuild uses ordered script modules that can be overridden locally.

Decide the unit, the ordering, how piw composes it into the image, whether example layers ship in repo, and how to state the security note that a layer script runs as root at build time.
