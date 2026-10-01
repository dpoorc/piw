---
id: 16
title: 'Decision: install model is a portable harness'
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

Is the clone the harness, or is the program separate from a user owned harness directory?

## Answer

The clone is the harness. A portable, self contained installation. Clone, install, move, reinstall. One directory the user chose, with no hidden state elsewhere.

It holds because of one rule: user content lives only in gitignored paths, and piw never writes a tracked file after install. Today that already holds. .pi/, extensions/, and .env are untracked, and config-seeds/ is only a seed.

PIW_HOME stays as an override for anyone who wants the program and the harness separated. It is not the default and not required.

Costs recorded: two harnesses mean two copies of the program; git pull conflicts if a user edits tracked files; the GitHub Use this template flow gives unrelated history, so the docs must recommend git clone and fork instead; the harness directory mixes upstream paths with pi paths.
