---
id: 23
title: Packaging and invocation
status: closed
priority: medium
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 24
    depends-on:
        - 16
        - 17
        - 18
        - 19
        - 20
        - 21
        - 22
created: "2026-09-29"
updated: "2026-09-30"
closed: "2026-09-30"
---

## Question

What is the skill's shape: one SKILL.md or support files, helper
scripts or pure prompt, model-activated or user-invoked, and how does
the user invoke it?

## Answer

### Name and invocation

- Name: `pre-publication`.
- User-invoked: `disable-model-invocation: true`. The agent must not
  start a scan unprompted. The catalog lets the agent route to it
  when the user asks.
- Content stays harness-agnostic.
- Shipped as a piw system skill at `skills/system/pre-publication/`.
  No separate repo for v1. Regenerate the catalog with
  `piw generate-catalog`.

### Structure

- `SKILL.md` - the procedure: intake, inventory, scan, report, gated
  fixes.
- `checks.md` - per-vector check reference (secrets, PII, metadata,
  hygiene, licensing), loaded on demand.
- `scripts/` - deterministic helpers.

### Scripts

- `inventory` - carrier inventory and extension and content mismatch.
- `history-scan` - enumerate git objects and sizes, and orchestrate
  the scanner over history.
- `gitignore-check` - gaps and non-resilient entries.
- `metadata-scan` - `exiftool` wrapper.
- `report` - render and sanitize.

Python 3 standard library only, no third-party dependencies. No
hand-rolled secret or PII rule sets. Judgment - the soft filter,
classification, and remediation choice - stays with the agent.

### Tools

Required:

- `gitleaks` - always. Scans the working tree (`gitleaks dir`) and
  history (`gitleaks git`).
- `exiftool` - when metadata carriers exist.
- `git-filter-repo` - when a history rewrite is chosen.
- `presidio` - for content PII.

Optional enhancers, suggested from the inventory:

- `trufflehog` - archives and binaries, live verification. Invoke
  only, never bundle (AGPL-3.0).
- `Kingfisher` or `Titus` - Apache-2.0 alternative.

Intake reports tool presence and prints install instructions. It
never auto-installs. A missing required tool stops the relevant
check. The skill does not substitute a weaker scan.

### Non-git projects

`gitleaks dir` scans the working tree without git. The history carrier
is absent. Do not force `git init`.

### Invocation

- Optional project root. Default: current directory.
- Optional public mode. Default: open source.
- Runs intake before any scan.
