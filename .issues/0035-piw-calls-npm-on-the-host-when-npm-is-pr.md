---
id: 35
title: piw calls npm on the host when npm is present
status: open
priority: high
labels:
    - kind:bug
relations:
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

Found while resolving #21.

`_npm_latest_version` (piw line 389) checks `command -v npm` and runs `npm view` on the host when npm is present. It falls back to `docker run` only when npm is absent.

That breaks the invariant that every install and every tool call runs in the container. It also makes the result depend on the host, so two machines can resolve different versions.

## Callers

Lines 430, 587, 1121, and 1156. These are the pi package and update paths.

## Work

- Delete the host branch. Always resolve inside the container.
- Check whether `ensure_archives` has the same shape. It uses curl on the host to fetch build inputs. Fetching is not installing, so this may be acceptable, but decide it explicitly and write the answer down.

## Acceptance

- A test asserts that no host-side command other than docker is invoked.
