---
id: 16
title: Report format and gated-fix protocol
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 17
        - 23
    depends-on:
        - 14
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

What does the report contain, how are fixes proposed, and how does
per-action approval work? How are irreversible actions (history
rewrite, deletion) gated, and what undo or backup is required?

## Answer

### Report location

Default `./.local/prepublish/` at the project root. The directory is
gitignored, so the report is never committed.

- On first run, verify the path is gitignored. If it is not, add it
to `.gitignore` as a gated fix, or stop and tell the user. Never
write a report into a tracked path.
- The convention names the directory, not each file. A scan may
produce several output files.
- Exclude exactly `.local/prepublish` from the inventory and from all
checks, always. The report must never be scanned as a finding.

### Report structure

1. Header - project root, date, "public" mode, detected inventory,
   tool versions.
2. Declared known risks - found, not found, not checked.
3. Findings - grouped by severity. Each carries class, carrier,
   location, confidence, and remediation kind.
4. Skipped checks - coverage gaps.
5. Suggested remediation plan - ordered.
6. Non-findings summary.

### Redaction

The default report is NOT sanitized. It may contain secret values.
The agent history already contains them, and the report is not
published. Redaction at this level buys nothing.

An optional sanitized export exists for handing to someone else. A
separate file, for example `report-sanitized.md`. It keeps class,
carrier, severity, remediation kind, and location. It strips values
and raw snippets, and its header says it is sanitized.

### Fix proposal

Propose the exact action - the command, or the patch with a diff.
Nothing is applied without approval. Low-risk reversible fixes may
be batched into one approval. Everything else stays per-action.

### Irreversible gate

Destructive actions: git history rewrite, file deletion, metadata
stripping that loses the original, and credential rotation (external).

- A separate confirmation lists exactly what is destroyed.
- Before history work, take a named backup (a backup ref or
  `git bundle`) and print the restore command.
- Credential rotation is a hand-off. The skill tells the user to
  rotate. It cannot do it.

### Verdict

No binary "safe to publish". A readiness summary instead: blocking
findings still open, and the status of declared known risks. The
skill reports coverage and risk. It does not certify.

### Tracked versus untracked weight

A finding's carrier, and whether it is tracked in git, set the
remediation and the ordering - not the severity tier. This is
consistent with `#14`: severity is harm, and exposure is not tracked
per finding.

- Tracked in git: history rewrite or forward fix. Highest weight.
- Untracked, or under a gitignored path: forward fix or add
  protection. Lower weight, because the repo will not publish it.
  A release or export artifact can still carry it.
