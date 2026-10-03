---
id: 47
title: Describe the environment to the agent
status: open
priority: medium
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    depends-on:
        - 44
created: "2026-10-03"
updated: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Environment description for the agent**.

## What to build

The agent is told what the environment is, not what is installed. It is pointed at the tool manager and at `PATH` and left to explore, because listing tools and versions produces a document that is accurate on the day it is written and wrong the first time anyone installs something.

Two things exploration cannot reveal are stated plainly. The container is not the host, so some tasks need host-side functionality it cannot reach; that is a property of the environment, not of any one tool. And a tool that is absent is not a problem to work around: the agent proposes it, and the proposal names the layer it belongs in.

The skills section describes the real layout and the mark that hides a skill from the prompt, and points at the catalog. The old sections describing discovery tiers that do not exist and a variant that no longer exists are removed. The always-present system-prompt addition does not grow: it keeps its must-reads, and the catalog stays a lookup rather than a standing obligation.

## Acceptance criteria

- [ ] The environment section names no tool and no version
- [ ] It states that the container cannot reach host-side functionality, without naming any single tool
- [ ] It tells the agent to propose a missing tool rather than work around it, and to name the layer
- [ ] The skills section describes the real layout, the hiding mark, and the catalog
- [ ] The sections about discovery tiers and variants are gone
- [ ] The always-present system-prompt addition keeps exactly its existing must-reads

## Blocked by

- #44 Populate the store and settle the command set
