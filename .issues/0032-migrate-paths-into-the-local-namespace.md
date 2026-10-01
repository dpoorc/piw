---
id: 32
title: Migrate paths into the .local namespace
status: open
priority: high
labels:
    - wayfinder:task
relations:
    depends-on:
        - 20
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

Apply the decision in #20 across the tree.

## Work

- Delete `.pi/` from the harness root. Move `agent`, `app`, and `store` under `.local/`.
- Move `extensions/` to `.local/extensions/`.
- Move `.env` to `.local/.env`. Keep the basename, so the permission deny rules keep matching.
- Update `piw`: 26 references to `.pi/`, plus the three resolvers and every mount.
- Update `.gitignore` and `.dockerignore`. `.dockerignore` must exclude `.local`.
- Update the 12 documentation files that mention `.pi/`.
- Create the namespace with the right ownership on first run, as `ensure_tools_dir` does today.

## Acceptance

- `git status --porcelain` is empty after a full piw run.
- No tracked path is written after install.
- pi reports no deprecated-directory warning when the workspace is the harness directory.
