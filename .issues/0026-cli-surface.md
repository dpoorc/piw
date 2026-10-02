---
id: 26
title: CLI surface
status: open
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 29
        - 30
    depends-on:
        - 21
        - 22
        - 24
        - 25
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

What is the final command set, and what does each command do?

Known changes: the --profile flag and the profile concept go away. #25 drops the two tool scopes and adds one command that installs the project's own tools. The user manifest and layers need commands or flags. pi update self and pi install are invoked in the container rather than reimplemented.

Also decide whether the argument parser needs further hardening, given the subcommand collision fixed in 4e74ccc.
