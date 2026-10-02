---
id: 34
title: Environment description for the agent
status: open
priority: medium
labels:
    - wayfinder:grilling
relations:
    depends-on:
        - 21
        - 22
        - 28
        - 38
        - 37
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-02"
---

The variant skill dies with variants, but the need it served does not. The agent must know what the environment provides.

Today: one hand-written `SKILL.md` per variant, mounted read-only at `skills/variant/SKILL.md`.

Under the new model the environment is derivable: the baked defaults, the active layers, and the store contents. So the description can be generated rather than written by hand.

## Questions

- Generated from the manifest and the store, or written by the user?
- Where does it live? A skill, `APPEND_SYSTEM.md`, or a file the agent reads on demand?
- What belongs in it? Tool names and versions, or only the capabilities that matter?
- What keeps it true after a tool is added or removed?

## Input from #25

Project tools do not belong in a global environment description. A project that
needs its own note writes it in its own `AGENTS.md`, and harness behaviour
belongs in the workflow skill, which is already mounted and read at session
start. So this ticket may resolve to "nothing global is needed", and that is a
valid answer.
