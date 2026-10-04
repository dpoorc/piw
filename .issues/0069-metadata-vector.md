---
id: 69
title: Metadata vector
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 74
    depends-on:
        - 64
        - 65
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#62 - Spec: pre-publication sterilization skill

## What to build

`exiftool` scan and selective removal, the commit identity options, and
the repository metadata checklist.

## Acceptance criteria

- [ ] Selective removal keeps functional tags, including orientation.
- [ ] A strip-all option exists, is opt-in, and warns that it drops functional tags.
- [ ] In-place edits are gated as destructive, and the file is re-read to confirm.
- [ ] Commit identity options are presented: project identity for future commits, rewrite for the past, mailmap for display.
- [ ] The repository metadata checklist includes credentials embedded in remote URLs.
- [ ] The fixture image EXIF and Office author field are found.

## Blocked by

- #64 - Inventory and report skeleton
- #65 - Fixture project and seam harness
