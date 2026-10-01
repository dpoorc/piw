---
id: 25
title: How does a project declare its tools?
status: open
priority: medium
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 26
    depends-on:
        - 24
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

Does a project declare its own tools, and if so how?

Re-scoped by #22 and #5. Project level layers are dropped: per project images would rebuild or accumulate, and apt packages are rarely project specific. Project level tools are probably mise's job already, because mise reads a project's `mise.toml` and the container's working directory is the workspace.

Decide:

- Is that enough, or does piw need to do something?
- Does piw install project tools at launch, or leave it to the agent on demand?
- What happens when the project pins a version that is not in the store?
- Is the answer simply "no project scope, document mise"?

A "no" is a valid and useful answer. The ticket exists so the answer is written down rather than assumed.
