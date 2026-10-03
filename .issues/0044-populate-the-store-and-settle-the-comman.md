---
id: 44
title: Populate the store and settle the command set
status: closed
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    blocks:
        - 45
        - 47
    depends-on:
        - 43
created: "2026-10-03"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **CLI surface** and the store half of **Migration of today's variants**.

## What to build

Tools beyond the base image live in the store, managed by mise, and survive an image rebuild. Building installs them as well as building the image, so the first launch is instant rather than stalling on a download. Updating them afterwards needs no rebuild.

The command set is the decided one. Each command declares its own flags, so a flag that belongs to another command is an error rather than a silently dropped argument. Launching is the default case, not a command word. Managing tools and layers is explicit, and there is no project command, because piw manages the harness and not the project.

`doctor` reports rather than judges: it checks that Docker and the daemon are reachable, that the image exists, that the store agrees with the manifest, and whether the seeded config files have drifted from their seeds. Drift is a diff, not a failure.

## Acceptance criteria

- [ ] Tools install into the store, not the image, and survive an image rebuild
- [ ] Building populates the store, so a first launch installs nothing
- [ ] Every command declares its flags, and a mismatched flag is an error that names the command
- [ ] Launching is the default case and there is no `launch` command word
- [ ] Installing and uninstalling the CLI are `link` and `unlink`, with readme and help text explaining what they do
- [ ] Layers can be listed, inspected, added, and updated, and adding scaffolds or adopts as appropriate
- [ ] `doctor` reports four checks and treats seeded drift as a diff
- [ ] `--version` and `--help` work

## Blocked by

- #43 Compose layers into an image
