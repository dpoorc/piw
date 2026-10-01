---
id: 14
title: Leak-vector taxonomy and severity model
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 16
        - 18
        - 19
        - 20
        - 21
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

What is the complete set of leak vectors, and what severity model
ranks findings so the report orders work by risk?

## Answer

### Shape

A class-by-carrier matrix. Classes say what the leak is. Carriers
say where it sits.

Carriers: working tree, git history, file and document metadata,
build artifacts and binaries, release or export artifacts (PDF, zip,
packaged bundle).

Git history is a carrier, not a class.

### Vector classes

1. Secrets and credentials.
2. Personal data (PII).
3. Confidential references - internal codenames, private URLs,
   client names, unpublished plans, internal ticket links.
4. Unwanted metadata - author fields, GPS and EXIF, document
   properties, commit identity.
5. Hygiene and exposure risk - stray files, large binaries, TODOs,
   absolute local paths, editor and OS artifacts, `.gitignore` gaps,
   a missing `LICENSE`. Holds positive leaks and missing-protection
   findings together.
6. Licensing and attribution defects.

### Severity

Four tiers, with a class default and a per-finding override:

- **critical** - a live secret, or personal data anyone can reach.
- **high** - confidential material, or a revoked or expired secret
  that is still sensitive.
- **medium** - metadata and hygiene findings that reveal more than
  intended.
- **low** - cosmetic leaks such as local paths and editor artifacts.

No score. Tiers are enough to order work.

### Remediation kind

A second field, separate from severity:

- forward fix - delete or redact in a new commit
- history rewrite - remove it from git history
- rotate credential - invalidate the secret
- add protection - add `.gitignore`, add `LICENSE`

This stops the report from ordering history-rewrite work by severity
alone.

### Confidence

Per-finding: certain, likely, possible. Detection produces false
positives, so a dismissal must not need a second pass.

### Known risks replace exposure tracking

No per-finding exposure field. At intake, before the scan, the skill
asks the user to declare known risks - anything the user knows is in
the project that should not become public. Each declared risk gets a
status after the scan: found, not found, or not checked. A declared
risk the scan misses is a detection gap worth surfacing.

Absent a declared risk, the skill does not track exposure. The user
dismisses or highlights findings from their own evaluation.

### History edits are judgement calls

Git history work is project-dependent. Commit identity may need
rewriting or may be fine. History may need a squash or may not. The
skill presents the options - keep as-is, squash, rewrite identity -
and the user decides. It never treats a history edit as required on
its own. `#17` owns the mechanics.
