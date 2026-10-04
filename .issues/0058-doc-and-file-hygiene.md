---
id: 58
title: Doc and file hygiene
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 60
    depends-on:
        - 51
        - 52
created: "2026-09-29"
updated: "2026-09-30"
closed: "2026-09-30"
---

## Question

What is "doc and file hygiene" for this skill? Cover stray files,
large binaries, internal references, TODOs, absolute local paths, and
`.gitignore` gaps.

## Answer

### Scope

The check list is open-ended, not exhaustive.

- **Stray files** - editor and OS artifacts (`.DS_Store`, `Thumbs.db`,
  `desktop.ini`), editor dirs (`.vscode`, `.idea`), backup and swap
  files (`*~`, `*.bak`, `*.orig`, `*.rej`, `.#*`), logs, crash dumps,
  local databases, scratch dirs. Empty files and broken symlinks are
  low findings.
- **Large binaries** - see below.
- **Internal references** - private URL shapes, internal hostnames,
  absolute home paths, personal names in comments, internal ticket
  IDs.
- **Leaky TODO, FIXME, and HACK comments.**
- **`.gitignore` gaps.**
- **Extension and content mismatch** - from `#52`.
- **Doc hygiene** - the same content checks applied to prose: internal
  references, absolute paths, draft markers, personal notes, "do not
  publish" text. Not doc-reality checking, which stays with
  `verify-docs`.

File-system metadata (ownership, xattrs, permissions) stays with `#55`.

### Internal references, TODOs, and the feel of a file

Generic patterns are always reported: private URL shapes, internal
hostnames, absolute home paths, internal ticket links. TODO, FIXME,
and HACK comments are reported only when they carry leaky content - a
name, a private link, an internal ticket, or "do not publish"
language. A generic TODO is not a finding.

Automated PII and known-pattern hits are the straight path. Beyond
those, the filter is soft: if a file reads like an internal-facing
document, treat it as one. Specific codenames come from a
project-supplied list, through known risks or config, not from
guesswork.

### Sensitive-information reference

A multi-round detection aid:

- Built from known risks, detected secrets and PII, and file-level
  judgments.
- Later rounds use it to find more elusive occurrences.
- Lives in `.local/prepublish/`, gitignored and excluded from the
  scan.
- Optional. Scale and depth vary by project. A project that does not
  need it skips it.
- The scan stops when a round adds nothing new.
- Persist it in `.local/prepublish/` for reuse or refresh on a later
  run. Never include it in the sanitized export.

### Large binaries

- One configurable threshold, default 5 MB per tracked file.
- Hard flag for anything above 50 MB.
- Report tracked and untracked separately. A tracked large file is a
  repo problem. An untracked one is only an export problem.
- Action is a forward fix, or history rewrite under `#54` when it is
  in history.

### .gitignore gaps

Use `git check-ignore` and `git status --ignored`. Two findings: a
local artifact that is present but not ignored, and a standard ignore
that is missing for a detected carrier (build outputs, editor dirs,
local scratch). Action is `add protection`.

Ignore entries must be resilient. Prefer directory and pattern
ignores over direct file ignores.

- Bad: `src/notes/about-damien.md`, `docs/ref/competitor-product-re/`,
  `bin/testing2.exe`, `handoff-2026-02-17.md`.
- Good: `src/prototypes/`, `.local`, `docs/session/`, `*.exe`.

A direct file ignore names the leak and fails as soon as the file is
renamed.

### Severity

Full four-tier scale, with class defaults and a per-finding override,
consistent with `#51`:

- **critical** - content damaging on its own if published, such as an
  unpublished legal matter or a live incident report.
- **high** - internal-facing documents, confidential references,
  tracked large binaries.
- **medium** - unignored local artifacts, personal names in paths.
- **low** - editor artifacts, strays, empty files, broken symlinks.

### Remediation

`forward fix` (delete or redact), `add protection` (`.gitignore`), or
`history rewrite` under `#54` when the file is tracked in history.
