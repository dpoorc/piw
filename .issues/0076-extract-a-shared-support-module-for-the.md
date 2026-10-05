---
id: 76
title: Extract a shared support module for the pre-publication scripts
status: open
priority: medium
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    related-to:
        - 75
created: "2026-10-05"
updated: "2026-10-05"
---

## Parent

#75 - Pre-publication review follow-ups

## What to build

The pre-publication scripts repeat shared helpers. `read_text` is
defined four times. `OUTPUT_SUBPATH` is declared in several files.
`SEVERITY_RANK` is copied. `is_git_repo` has two implementations.
`finding()` has three different contracts. `import tempfile` repeats in
the tests. The `--stdout` flag means different things in `report.py`
and in the vector scripts.

Extract one support module. The vector scripts import it. Keep the
behaviour the same.

## Acceptance criteria

- [ ] One module holds `read_text`, `OUTPUT_SUBPATH`, `SEVERITY_RANK`, and
  `is_git_repo`.
- [ ] The vector scripts import the shared helpers.
- [ ] `finding()` has one documented contract, or each vector names its
  own helper clearly.
- [ ] The `--stdout` flag has one meaning.
- [ ] Seam A passes.

## Source

Standards axis. Duplicated Code, Mysterious Name, Primitive Obsession.
