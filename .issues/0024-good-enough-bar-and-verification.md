---
id: 24
title: Good-enough bar and verification
status: closed
priority: medium
labels:
    - wayfinder:grilling
relations:
    depends-on:
        - 23
created: "2026-09-29"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

What is the good-enough bar for v1, and how do we verify the skill
meets it?

## Answer

### Good-enough bar for v1

1. **Cold-run works** - a fresh session with only the skill files runs
   intake, inventory, scan, report, and gated fixes end to end.
2. **Findings match** - every planted finding in the fixture is
   reported with the right class and carrier.
3. **Gating holds** - no mutation without approval, irreversible
   actions require the backup and confirmation, and a missing required
   tool stops that check.
4. **No decision-tracking references** in the artifact. Grep-able.
5. **Tool intake works** - presence and absence reported with install
   instructions.
6. **Known limits are named** in the artifact.

### Verification method

A fixture project with planted findings:

- a fake secret in the working tree, and one in git history;
- a PII string;
- an image with EXIF;
- an Office document with an author field;
- a stray artifact;
- a non-resilient `.gitignore` entry;
- a tracked large file.

Write the expected-findings list first. Run the skill cold against the
fixture and compare. Objective and repeatable, unlike a role-play.

### Gates

- **G1 hygiene** - no decision-tracking references in the artifact.
- **G2 cold run** - the fixture test passes.
- **G3 safety** - gating behavior verified: approval required, backup
  before rewrite, missing tool stops.

No neutrality pass. That was specific to the documentation skill.

### Known limits

Name these in the artifact so a user knows where coverage stops:

- live verification;
- hosted services;
- non-English PII;
- very large repos;
- archive and binary extraction;
- non-git history;
- Windows paths;
- submodule history (submodule contents and vendored code are scanned
  as ordinary tree files, but a submodule's own history lives in
  another repo and is not scanned; vendored code may need allowlists).

### Handoff

Implementation runs through `to-spec`, `to-tickets`, and `implement`.
The map hands off; it does not build.

Verification is the fixture test, run by the agent, plus one run on a
real project that the user reviews for report quality.
