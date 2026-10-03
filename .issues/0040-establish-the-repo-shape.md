---
id: 40
title: Establish the repo shape
status: open
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    blocks:
        - 41
        - 42
created: "2026-10-03"
updated: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Repo shape: public content vs user state** and **Naming**, and takes over the namespace half of #32.

## What to build

One gitignored namespace holds every piece of user state, so the tracked tree stays clean and an upstream pull never touches the user's work. The seeded defaults move into a tree of their own, named for what they do rather than for one kind of file they hold.

The variant scaffolding goes, because variants go: the placeholder skill that existed only as a mount target, the variant directories, and the template. The image prefix becomes `piw`, so nothing in the repo still names the project by its old name. The ignore file is the contract: everything user-owned is ignored, and everything generated stays where it is regenerated.

## Acceptance criteria

- [ ] A single ignored namespace holds the agent directory, the store, the manifest, the layers, the mise config, and the environment file
- [ ] The seed tree is renamed to `seed/` and holds the config seeds, the starter manifest, and the starter mise config
- [ ] `skills/variant/` and the `variants/` tree are gone, along with the variant skill mount
- [ ] The image prefix is `piw`, so images are `piw:default` and `piw:local`
- [ ] `git status` is clean after a launch, and no tracked file is written after install

## Blocked by

None — can start immediately.
