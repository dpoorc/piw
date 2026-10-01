---
id: 19
title: 'Research: prior art for extensible defaults'
status: closed
priority: high
labels:
    - wayfinder:research
relations:
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

How do established tools ship a minimal sane default plus a user extension mechanism, and which projects treat a cloned repository as the working directory?

## Answer

Resolved. Every surveyed mechanism uses the same three part answer: keep a small base, let the user declare additions in a file outside the upstream tree, and run privileged install steps in a build step. Closest precedents are devcontainer Features and BlueBuild modules. The cloned repo pattern is used by yadm and bare git dotfiles, while chezmoi, home-manager, pre-commit, direnv, just, devcontainers, and Docker Compose keep the program global and the configuration separate. Full report in docs/research/2026-10-01-extensibility-prior-art.md.
