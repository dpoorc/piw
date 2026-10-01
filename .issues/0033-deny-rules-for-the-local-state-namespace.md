---
id: 33
title: Deny rules for the local state namespace
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

Found while resolving #20.

The permission rules deny the basename `.env`, `*.pem`, and `*.key`. They do not cover pi's `auth.json`. When the workspace is the harness directory, the agent can read `.local/agent/auth.json` today.

## Work

- Deny the state namespace: at minimum `.local/agent/auth.json` and the secrets file.
- Keep `.local/config/` readable, because the manifest describes the environment and the agent may need it.
- Check whether `.local/agent/sessions/` should be readable.
- Confirm that the existing `.env` rule still matches after the move.

## Acceptance

- A test asserts that a read of the secrets file and of `auth.json` is denied.
