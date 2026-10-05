---
id: 89
title: Correct the licensing severity note and the stale skill text
status: open
priority: low
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

Three text defects:

- `checks.md` says a missing third-party notice is `high`. The Apache
  NOTICE finding is `medium`.
- `SKILL.md` says the remaining scan vectors arrive later. All vectors
  are implemented.
- `tests/README.md` says the fixture does not use a sequential token
  shape. `FAKE_HISTORY_SECRET` is sequential.

Correct the text, or change the code to match the text. Pick one for
the NOTICE severity.

## Acceptance criteria

- [ ] The severity note matches the code.
- [ ] The stale skill text is gone.
- [ ] The fixture note matches the fixture.

## Source

Spec axis and Standards axis.
