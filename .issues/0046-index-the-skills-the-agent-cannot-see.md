---
id: 46
title: Index the skills the agent cannot see
status: open
priority: medium
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    depends-on:
        - 42
created: "2026-10-03"
updated: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Low-frequency skills**.

## What to build

A skill marked as unavailable for automatic selection is removed from the system prompt but stays invocable by name. The harness already uses that mark for most of its skills, so most of them cost nothing per turn and are invisible to the model. The catalog is how the model learns they exist: it lists only the hidden ones, because the visible ones are already in the prompt, and it names the path to each.

The generator runs in the container, where python3 exists, rather than on the host, where it is not guaranteed. It fails loudly: a skill whose description cannot be read is an error, never an empty entry, which is how the committed catalog came to be full of blank descriptions.

## Acceptance criteria

- [ ] The catalog lists only skills excluded from the system prompt, with a path for each
- [ ] A skill marked for explicit invocation only is absent from the system prompt and still invocable by name
- [ ] The generator runs in the container and never on the host
- [ ] An unreadable description is an error that names the skill, never a silent empty entry
- [ ] Every active vendor bucket is covered, including the one holding the four misc skills
- [ ] The generated catalog is reproducible: running it twice changes nothing

## Blocked by

- #42 Rebuild the container seam
