---
id: 20
title: 'Repo shape: public content vs user state'
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 21
        - 22
        - 24
        - 29
        - 32
        - 33
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

How does the repo separate public upstream content from user state, so that git pull stays clean and the split is obvious?

Leading idea from the user: a single gitignored local state namespace, for example .local/, holding everything user owned. Today the untracked paths are scattered across .pi/, extensions/, and .env.

Decide the namespace, what moves into it, what stays where, whether the pi paths under .pi/ remain, and how the rule is enforced.

## Answer

The harness has exactly one user-owned namespace, `.local/`, and it is
gitignored. Every other path in the tree is upstream content. `.pi/` is
deleted from the harness root.

### Layout

```
.local/
├── env           secrets (was .env at the root)
├── config/       piw's user configuration: manifest and layers
├── extensions/   pi's global extensions, user-owned (was extensions/)
├── agent/        pi's agent directory (was .pi/agent)
├── app/          pi's program install (was .pi/app)
└── store/        the tool store (was .pi/store)
```

### Why

- One ignored directory makes the public/private split visible from the
  root. Today `extensions/` sits between `docs/` and `piw`.
- `.pi/` belongs to pi. piw must not put its store inside another
  program's namespace.
- pi scans `<workspace>/.pi/` for project configuration. Removing `.pi/`
  from the root stops pi from reading harness state as project
  configuration. That is the defect that forced the store rename from
  `.pi/tools` to `.pi/store`.
- `.local/` is a convention here, not a claim about `$HOME`. This
  repository does not shadow a user's home directory.

### Generated artifacts stay put

`build/archives/`, `skills/catalog.md`, `skills/variant/`, and
`docs/handoffs/` stay where they are and stay ignored. They are generated,
not user-owned. `build/archives/` must remain in the Docker build context,
because Docker cannot copy from outside it.

### Forking

The namespace is ignored by default. A user who wants to track their own
configuration un-ignores a subpath in their fork's own `.gitignore`, which
git supports with a `!` pattern.

### Enforcement

A test in `tests/run.sh` runs a scripted sequence of piw operations in the
sandbox, then asserts that `git status --porcelain` is empty.

### Consequences found while resolving this

- The permission rules deny the basename `.env`. A file named
  `.local/env` would not match, so the rule must be updated to match the
  new name. The rules are ours to change.
- No rule covers pi's `auth.json`, which the agent can read today when the
  workspace is the harness directory. The state namespace needs deny
  rules. See the new ticket.
- The variant skill mount disappears with variants, but the need it served
  does not. See the new ticket.
