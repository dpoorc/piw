---
id: 43
title: Compose layers into an image
status: open
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    blocks:
        - 44
    depends-on:
        - 39
        - 41
        - 42
created: "2026-10-03"
updated: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Layer mechanism** as amended by **Migration of today's variants**.

## What to build

A layer is a self-contained stack the user can switch on. It carries the apt packages it needs, the archives it needs, the store tools it needs, and an optional script for anything the three cannot express. A layer with only apt and store tools needs no script at all, so the script is optional.

Several layers are active at once, applied in order, composed into one image. That is what the old variants could never do: two of them were mutually exclusive because each forked the image, and layers do not fork it.

The image is generated in memory from the active set, never written to disk. Consecutive apt declarations merge into one package operation. Archives are fetched with a checksum, so verification stays in Docker's hands rather than in a shell script. A dry run prints the plan without invoking Docker.

## Acceptance criteria

- [ ] A layer directory may carry apt packages, archives, store tools, and an optional script, and needs no script when the others suffice
- [ ] Several layers compose into one image, applied in the declared order
- [ ] The generated image is `piw:local`, built from a Dockerfile that never exists on disk
- [ ] Consecutive apt declarations become one package operation
- [ ] Every archive is fetched with a checksum, and none is verified by a hand-written shell check
- [ ] A missing layer or script stops before Docker is invoked and names the entry and the expected path
- [ ] A dry run prints the plan and changes nothing

## Blocked by

- #39 Build the default image
- #41 Parse the manifest
- #42 Rebuild the container seam
