---
id: 41
title: Parse the manifest
status: closed
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    blocks:
        - 43
    depends-on:
        - 40
created: "2026-10-03"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **User manifest: format and location**.

## What to build

Two files describe what the user wants, and neither is translated into the other's format. Tools are declared where mise already reads them, and layers are declared in a line-oriented file that `piw` reads with POSIX awk, because the host is not guaranteed to have python3, jq, or yq.

A starter copy of each lives in the seed tree and is written only when the target is absent, so an established user keeps their file and a new one starts from something that works.

## Acceptance criteria

- [ ] The mise config is TOML and is parsed by mise alone; `piw` never reads or writes its contents
- [ ] The layer manifest is line-oriented and is readable with POSIX awk, with no dependency beyond the shell
- [ ] A malformed line is an error that names the file and the line, never a silent skip
- [ ] Both starters are seeded on first install and never overwritten afterwards
- [ ] An environment variable can relocate the manifest, but the default needs no configuration

## Blocked by

- #40 Establish the repo shape
