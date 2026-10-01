---
id: 30
title: Secrets vector
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
relations:
    blocks:
        - 35
        - 36
        - 37
    depends-on:
        - 27
        - 28
created: "2026-10-01"
updated: "2026-10-01"
---

## Parent

#25 - Spec: pre-publication sterilization skill

## What to build

`gitleaks` runs over the working tree and git history. Findings appear in
the report with class, carrier, severity, confidence, and remediation
kind. Gated fixes and the credential-rotation hand-off are wired.

## Acceptance criteria

- [ ] `gitleaks` is required; a missing tool stops this check with a clear message.
- [ ] Both the working tree and git history are scanned.
- [ ] Findings carry a confidence level.
- [ ] The rotation hand-off lists the affected credentials, the provider revocation location, and the confirmation step; publication stays blocked until rotation is confirmed.
- [ ] The fixture secret in the tree and the fixture secret in history are both found.

## Blocked by

- #27 - Inventory and report skeleton
- #28 - Fixture project and seam harness
