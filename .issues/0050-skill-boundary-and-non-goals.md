---
id: 50
title: Skill boundary and non-goals
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 59
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

What does the pre-publication skill do, what does it not do, and how
does it divide work with `verify-docs`, `code-review`, and existing
secret scanners? Which ancillary vectors (licensing, attribution,
authorship, naming) are in scope or out?

## Answer

### Identity

Procedure-first, tool-assisted. The skill owns the workflow and the
report. It may bundle helper scripts, and it falls back to
agent-driven checks when a tool is absent. It is not a wrapper around
a scanner.

Environment fact: the workstation variant has no `gitleaks`,
`trufflehog`, `detect-secrets`, `git-filter-repo`, or `mat2`. It has
`exiftool`, `rg`, `fd`, `jq`, `yq`, and `gpg`. The skill must not
assume a scanner exists.

### Ancillary vectors

- Licensing - in, narrowly. A missing `LICENSE` and a missing
  third-party notice.
- Attribution - in, narrowly. A missing or wrong attribution
  statement and an incompatible-license reference.
- Authorship - in, folded into metadata. Commit identity and
  document author fields.
- Naming - out. A rename is not leak prevention.

### Meaning of "public"

Input, not assumption. Open source, shared with one party, and
declassified carry different leak thresholds. Default to open source
when the user does not say.

### Project unit

One project root per run. A monorepo counts as one project.
Multi-repo is out of scope. No multi-repo handling is needed.

### Supply chain

Out of the v1 core. Dependency vulnerability scanning is a security
audit and needs a network and a vulnerability database. Leaked
internal package names inside manifests are not treated as a concern.

### Non-goals

- Code quality and architecture - `code-review`
- Doc-reality verification - `verify-docs`
- CI setup and configuration
- General refactoring
- Documentation writing
- License selection
- Dependency vulnerability scanning
- Performance work
- Renaming

### Boundary against `verify-docs` and `code-review`

The skill may invoke `verify-docs` as a step. It does not reimplement
it, and it does not own doc-reality checks. It does not perform code
review. The map records both as out of scope.

## Revision (2026-09-30, by #60)

The Identity section above says the skill "falls back to agent-driven
checks when a tool is absent". That is superseded. The skill requires
tools and stops the relevant check when one is missing. It does not
substitute a weaker scan, which would produce false confidence.
`#60` records the required and optional tools.

The environment fact above described the container at that time.
Tools are added to the container and the workspace as needed, so
absence at one moment does not shape the design.
