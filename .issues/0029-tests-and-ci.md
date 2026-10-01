---
id: 29
title: Tests and CI
status: open
priority: medium
labels:
    - wayfinder:task
relations:
    depends-on:
        - 20
        - 26
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
---

## Question

What does the test suite cover, and what does CI run?

Existing: tests/run.sh drives the real piw against a stub docker. It is hermetic and runs in under a second.

Add the git clean assertion that user operations never dirty the tree, coverage for the new CLI surface, and CI for publishing.
