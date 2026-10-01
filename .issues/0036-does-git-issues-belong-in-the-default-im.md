---
id: 36
title: Does git-issues belong in the default image?
status: open
priority: medium
labels:
    - wayfinder:grilling
relations:
    related-to:
        - 13
        - 23
created: "2026-10-01"
updated: "2026-10-01"
---

Found while resolving #23.

The current core image builds `git-issues` from a `golang:latest AS git-issues-builder` stage and copies the binary to `/usr/local/bin`. It is not in T0 or T1, and the default image decision in #15 does not mention it.

The builder stage pulls a large Go image to compile one small tool, which is a real cost in a lean default image.

The question is also a principle question: the map says the author's personal toolset must leave the repo's defaults, and `git-issues` is this project's issue tracker.

## Options

- Keep it in the default image, and add it to T0.
- Move it to a seeded layer in `config-seeds/layers/`.
- Make it a store tool, installed by mise.
- Drop it, and let users install it themselves.

## Note

It is already a Go binary, so a store tool via mise's `go:` backend would work and would cost nothing in the image.
