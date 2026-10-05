---
id: 81
title: Check the reflog and the hook contents in the metadata vector
status: closed
priority: medium
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    related-to:
        - 75
created: "2026-10-05"
updated: "2026-10-05"
closed: "2026-10-05"
---

## Parent

#75 - Pre-publication review follow-ups

## What to build

Spec #55 lists the reflog and the git hooks under repository metadata.
`scan_repository` omits the reflog and does not inspect hook contents.

Add the reflog check. Inspect the hook files for a local path or a
credential.

## Acceptance criteria

- [ ] A reflog finding is emitted when the reflog holds entries.
- [ ] A custom hook with a local path or a credential is reported.
- [ ] Seam A passes.

## Source

Spec axis. Spec #55.
