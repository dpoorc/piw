---
id: 10
title: 'Bug: auto-compaction threshold too high for long-context models'
status: open
priority: high
labels:
    - kind:bug
    - state:needs-triage
created: "2026-09-11"
updated: "2026-09-11"
---

## Summary

DeepSeek-V4-Flash loses accuracy at 15-20% of its context window; auto
compaction at ~1M context is far too late. The practical target is around
150-200k tokens. Source: todo.md item 2 (moved here during repo restructure,
2026-09-11).

## Status

- `config-seeds/models.json` already caps the flash models: 210000 (Fireworks
  override) and 122880 (SiliconFlow contextLength). Verify whether that cap
  matches the real provider windows and whether pi compacts at a sane
  threshold with it.
- Plain "DeepSeek V4" entries still sit at 131072. Verify the compaction
  threshold against actual usage.
