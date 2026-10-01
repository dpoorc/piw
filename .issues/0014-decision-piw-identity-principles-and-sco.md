---
id: 14
title: 'Decision: piw identity, principles, and scope'
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

What is piw, what principles rank highest, and where is the boundary with pi?

## Answer

piw is a launcher and wrapper around pi that manages isolation and environment. pi owns behaviour: its own install, extensions, skills, prompts, and settings.

Principle order on conflict: isolation > transparency > leanness > composition.

Transparency is re-scoped to transparent configuration. Third-party tools are allowed, as Docker and pi already are, provided state stays inspectable and pinned versions stay visible.

Security invariant: the host is never touched outside the mounted paths. Mid-session installs are allowed when contained.

Two tool scopes exist. Workspace-native tools serve one project. Universal tools serve most users.

Publishing is the intent, so defaults must not encode one person toolset.
