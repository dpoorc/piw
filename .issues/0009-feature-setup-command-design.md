---
id: 9
title: 'Design: setup command for first-run provisioning'
status: open
priority: medium
labels:
    - kind:feature
    - setup
created: "2026-09-11"
updated: "2026-09-11"
---

## Summary

Provide a first-run provisioning path so a new machine can bootstrap the
harness with minimal manual steps. Source: todo.md item 1 (moved here during
repo restructure, 2026-09-11).

## Notes

- There are several ways to go about this: a setup skill, a setup command, or
  both. A setup command could invoke the setup skill.
- Proposed flow: gather facts (if any) -> build at least the core variant ->
  install packages -> write an install log -> start piw with a prompt to start
  the setup skill -> read the install log -> guide the user through the rest
  of the setup procedure -> surface detected issues.
