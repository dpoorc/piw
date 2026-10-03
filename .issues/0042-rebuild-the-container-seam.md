---
id: 42
title: Rebuild the container seam
status: open
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    blocks:
        - 43
        - 46
    depends-on:
        - 40
created: "2026-10-03"
updated: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Store layout and the container mount map**.

## What to build

Every container invocation goes through one helper, so the mount map, the environment, and the user identity are stated in exactly one place. The map is the whole contract between host and container: what the agent may read, what it may write, and what it must never see.

The harness becomes a read-only resource tree. Skills, agents, and the system-prompt addition mount read-only, which is safe because nothing in pi writes to those paths. Everything pi does write lives in the agent namespace. The user's own skills gain the cross-tool location. Secrets pass as an environment file rather than a hardcoded allowlist, so a new key needs no code change.

Read-only mode makes the workspace and the store read-only and adds no network. The agent namespace stays writable, because pi must record sessions and auth, and a read-only namespace would break pi rather than restrict the project.

## Acceptance criteria

- [ ] One helper builds every container invocation, and no caller assembles its own
- [ ] The mount map matches the decided one exactly, including the layer directory read-only
- [ ] No mount is read-write over tracked content
- [ ] Secrets pass by environment file, and the API key allowlist is gone
- [ ] Read-only mode makes the workspace and store read-only and adds no network
- [ ] The exact argv is asserted by a hermetic test, with no Docker daemon

## Blocked by

- #40 Establish the repo shape
