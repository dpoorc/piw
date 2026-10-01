---
id: 24
title: Store layout and the container mount map
status: open
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 25
        - 26
    depends-on:
        - 20
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

How is the store laid out, and how does the container see the pieces of `.local/`?

Re-scoped by #22. The two-scope design is gone: there is one harness store and one user image, so `MISE_SHARED_INSTALL_DIRS` and the project store are out of scope.

What remains is the plumbing. mise needs a writable data directory, a global config file, and a lockfile, and #21 placed the config outside the store at `.local/mise.toml`. `.local/` also holds the agent directory, the pi install, the extensions, and the layers, and each needs a different container path. `MISE_DATA_DIR` is read early, so it must come from the environment rather than a config file.

Decide:

- The layout inside `.local/store/`.
- Which pieces of `.local/` get a mount, at which container path, and read-only or read-write.
- The `PATH` order inside the container.
- What `piw tool install`, `list`, and `remove` read and write.
- Whether `.local/env` is passed as `-e` flags or as an env file.
