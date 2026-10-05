---
id: 91
title: Exclude the ignored local namespace from the pre-publication scan
status: open
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
created: "2026-10-05"
updated: "2026-10-05"
---

## Problem

The pre-publication scan walks the whole working tree. It excludes only
the output directory, `.local/prepublish`, by exact path. Every other
path under the ignored local namespace is scanned.

On the piw repo this is 137,962 files under `.local/` against 1,047
files of actual project content. The namespace holds the mise toolchain
store, npm, Go, and Rust caches, cloned third-party repositories, and
the live `.local/.env`. The PII vector would run presidio over roughly
91,000 text files, almost all third-party toolchain source. The result
is slow and noisy, and it buries the signal.

The published artifact is the git repo. `.local/` is covered by a
resilient `.local/` rule in `.gitignore` and never ships.

## What to build

Give the scan a scope boundary for the ignored local namespace.

Points to settle during implementation:

- Exclude `.local/` wholesale in `iter_files`, and mirror the exclusion
  in the gitleaks config. `iter_files` already excludes the output
  directory by exact path. The parent namespace is the natural boundary
  for this repo.
- Decide between a fixed exclusion and a configurable `--exclude` flag.
  A flag keeps the skill generic for projects that do not use `.local/`.
- Record each skipped path in the report as a skipped carrier, with the
  reason. The report already has a skipped-checks section.
- Reconcile with hygiene. The hygiene vector deliberately scans ignored
  files to find a local artifact that is not ignored. A blanket
  `.gitignore` exclusion would weaken that check. Use `git check-ignore`
  for ignore status, and keep content scans (secrets, PII) on the
  publishable scope.

## Evidence

`inventory.py` output on the piw repo:

- `.local/` files: 137,962
- all other files: 1,047
- text-like files under `.local/`: 25,353
- text files total per inventory: 91,471

## Acceptance criteria

- [ ] A scan of the piw repo does not descend into `.local/` beyond the
      output directory.
- [ ] The skipped namespace is named in the report.
- [ ] The secrets, PII, hygiene, and licensing vectors agree on the
      scope.
- [ ] A project with a different local-namespace convention can set the
      scope without a code edit, or the fixed convention is documented.
