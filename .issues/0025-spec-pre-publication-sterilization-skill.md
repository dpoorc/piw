---
id: 25
title: 'Spec: pre-publication sterilization skill'
status: open
priority: high
labels:
    - kind:feature
    - state:ready-for-agent
created: "2026-10-01"
updated: "2026-10-01"
---

## Problem Statement

A project is about to become public. Before that moment, it can leak
things it never meant to publish: live credentials in the working tree
or in git history, personal data, identity and location metadata,
internal-facing documents, stale artifacts, and licensing defects.
Today that check is manual, ad hoc, and easy to skip. Nothing in the
harness runs it, and a leak found after publication cannot be
recalled.

## Solution

A generic `pre-publication` skill that sterilizes a project before it
becomes public. It inventories what is present, scans the leak
vectors, produces a prioritized report, and applies approved fixes
through per-action gates. It is advisory-first: it never certifies a
project as safe, and it never mutates anything without approval. It
works on any project root, with or without git.

## User Stories

1. As a maintainer about to open-source a repo, I want to run one
   skill that finds what should not be public, so that I do not have
   to remember every leak vector myself.
2. As a maintainer, I want to state what "public" means for this
   project, so that the leak threshold matches the audience.
3. As a maintainer, I want to declare known risks at intake, so that
   the scan is measured against what I already suspect.
4. As a maintainer, I want each declared known risk to end as found,
   not found, or not checked, so that a miss is visible rather than
   silent.
5. As a maintainer, I want the skill to inventory what is actually in
   the project, so that the scan adapts to this project rather than to
   a guessed project type.
6. As a maintainer, I want checks that need a carrier to be skipped
   when the carrier is absent, so that the skill does not pretend to
   look where there is nothing.
7. As a maintainer, I want skipped checks listed in the report, so
   that I can see where coverage stopped.
8. As a maintainer, I want the tool check at intake, so that I know
   before the scan which tools are missing and how to install them.
9. As a maintainer, I want a required tool that is missing to stop its
   check, so that I never get false confidence from a weaker scan.
10. As a maintainer, I want secrets found in the working tree and in
    git history, so that a secret removed from the tip is still
    caught.
11. As a maintainer, I want secret findings to carry a confidence
    level, so that I can dismiss a false positive without a second
    pass.
12. As a maintainer, I want personal data found in content and in
    metadata, so that names, addresses, and identity fields do not
    ship.
13. As a maintainer, I want identity and location metadata removed
    selectively, so that functional tags such as orientation survive.
14. As a maintainer, I want the skill to flag files that read like
    internal-facing documents, so that elusive internal material is
    surfaced even without a pattern match.
15. As a maintainer, I want a multi-round sensitive-information
    reference, so that later rounds find more of what earlier rounds
    suggested.
16. As a maintainer, I want hygiene findings for strays, large
    binaries, leaky TODOs, absolute paths, and extension or content
    mismatch, so that the repo is clean as well as safe.
17. As a maintainer, I want `.gitignore` gaps reported with resilient
    patterns suggested, so that a rename does not reopen the gap.
18. As a maintainer, I want licensing and attribution defects flagged
    at a high level, so that I know to act, without the skill
    pretending to give legal advice.
19. As a maintainer, I want a missing license framed as a decision,
    so that I can add an explicit "all rights reserved" notice or
    choose a license.
20. As a maintainer, I want authorship advice to follow my
    preference, so that a project that wants named attribution is not
    treated like one that wants anonymity.
21. As a maintainer, I want findings grouped by severity with a
    separate remediation kind, so that "how bad" and "how to fix" are
    not confused.
22. As a maintainer, I want the report in a gitignored directory
    inside the project, so that it is easy to find and never
    committed.
23. As a maintainer, I want the report excluded from the scan, so that
    the skill does not flag its own output.
24. As a maintainer, I want a readiness summary rather than a verdict,
    so that the skill does not claim a safety it cannot prove.
25. As a maintainer, I want an optional sanitized report, so that I
    can hand findings to someone who should not see the values.
26. As a maintainer, I want each fix proposed as an exact action, so
    that I know what will happen before it happens.
27. As a maintainer, I want no mutation without my approval, so that
    the skill cannot damage the project.
28. As a maintainer, I want low-risk reversible fixes batchable, so
    that trivial cleanups are not one prompt each.
29. As a maintainer, I want a separate confirmation for destructive
    actions, listing exactly what is destroyed, so that irreversible
    work is deliberate.
30. As a maintainer, I want a named backup before any history rewrite,
    with the restore command printed, so that a mistake is
    recoverable.
31. As a maintainer, I want credential rotation handed off with the
    provider's revocation location, so that I know the leak is
    actually closed.
32. As a maintainer, I want publication blocked until rotation is
    confirmed, so that a rewritten history is not mistaken for a
    revoked secret.
33. As a maintainer, I want history rewrite to require
    `git-filter-repo` and never fall back, so that mangled history is
    not a risk.
34. As a maintainer, I want the skill to warn about forks, clones, and
    host caches, so that I know the rewrite is local until I deal with
    them.
35. As a maintainer, I want the skill to verify its own work after a
    rewrite, so that I can trust the result.
36. As a maintainer of a project without git, I want a full
    working-tree scan, so that I am not forced to `git init`.
37. As a maintainer, I want the skill to name its known limits, so
    that I know where coverage stops.
38. As a maintainer, I want the skill user-invoked, so that it never
    starts a heavy scan unprompted.
39. As a maintainer, I want the sensitive-information reference to
    persist in the gitignored directory, so that a later run can reuse
    it.
40. As a maintainer, I want to re-run the skill after fixes, so that I
    can confirm the project is clean.

## Implementation Decisions

### Packaging

- Name: `pre-publication`. Shipped as a piw system skill. Content
  stays harness-agnostic. No separate repository for v1.
- User-invoked: `disable-model-invocation: true`. The agent must not
  start a scan unprompted.
- Structure: a procedure file, a per-vector check reference loaded on
  demand, and a set of deterministic helper scripts.
- Invocation takes an optional project root (default: current
  directory) and an optional public mode (default: open source). It
  runs intake before any scan.

### Procedure

Intake, inventory, scan, report, then gated fixes. Nothing mutates
before the report is presented.

### Inventory, not classification

The skill does not classify projects into kinds. It inventories
content and meta layers, and scans against that inventory. Detection
uses extension as the baseline, plus directory convention and content
sniffing. A file that cannot be identified, or whose content
contradicts its extension, is itself a finding. The inventory is
open-ended; the meta-layer list is illustrative, not exhaustive.

Two check families:

- **Content checks** run over every text-like file regardless of
  carrier.
- **Carrier checks** require a carrier.

A skipped check is recorded as skipped.

### Taxonomy and severity

A class-by-carrier matrix. Classes: secrets and credentials; personal
data; confidential references; unwanted metadata; hygiene and exposure
risk; licensing and attribution defects. Carriers: working tree, git
history, file and document metadata, build artifacts and binaries,
release or export artifacts.

Severity is four tiers - critical, high, medium, low - with class
defaults and a per-finding override. A separate remediation kind:
forward fix, history rewrite, rotate credential, add protection.
Per-finding confidence: certain, likely, possible.

Declared known risks replace per-finding exposure tracking.

### Detection tools

Required: `gitleaks` (always, working tree and history), `exiftool`
(when metadata carriers exist), `git-filter-repo` (when a rewrite is
chosen), `presidio` (for content PII).

Optional enhancers suggested from the inventory: `trufflehog` (invoke
only, never bundle; AGPL-3.0) for archives, binaries, and live
verification, or Kingfisher and Titus (Apache-2.0).

Intake reports tool presence and prints install instructions. It never
auto-installs. A missing required tool stops its check. There is no
weaker fallback. Live verification is opt-in, because it needs network
and authorization.

### Report

Location: a gitignored directory at the project root, excluded from
the scan by exact path. Sections: header (project root, date, public
mode, inventory, tool versions); declared known risks with status;
findings grouped by severity with class, carrier, location,
confidence, and remediation kind; skipped checks; a suggested ordered
remediation plan; a non-findings summary.

The report is unsanitized by default. An optional sanitized export
keeps class, carrier, severity, remediation kind, and location, and
strips values and raw snippets.

The report ends with a readiness summary, never a binary verdict.

### Gated fixes

Each fix is proposed as an exact action: the command, or the patch
with a diff. Nothing is applied without approval. Low-risk reversible
fixes may be batched. Everything else is per-action.

Destructive actions - history rewrite, file deletion, metadata
stripping that loses the original, credential rotation - get a
separate confirmation that lists exactly what is destroyed. History
work additionally requires a named backup (a backup ref and a
`git bundle`), verified, with the restore command printed.

### Git history

Rewrite is user-approved, never automatic, and never a substitute for
rotation. Commit identity rewriting and squashing are separate
optional actions. Rewrite all local refs by default, never push, and
warn about forks, clones, CI artifacts, PR refs, and host caches.
After a rewrite, expire the reflog, garbage collect, and re-scan to
confirm. Rotation is a hand-off with the provider's revocation
location and a confirmation step; publication stays blocked until it
is confirmed.

### Metadata

`exiftool` is the primary reader. Remove identity and location tags
selectively; keep functional tags, including orientation. Support a
strip-all option with the rotation warning. Copyright and licensor
fields belong to the licensing vector, not here. Prefer out-of-place
writes and re-read to confirm. Commit identity options: project
identity for future commits, `git-filter-repo` for the past,
`.mailmap` for display only. Repository metadata to check includes
credentials embedded in remote URLs, `git config`, annotated tags,
notes, stashes, submodule URLs, hooks, `.git/description`, and the
reflog.

### Hygiene

Open-ended checks: strays, large binaries, internal references, leaky
TODO, FIXME, and HACK comments, `.gitignore` gaps, extension and
content mismatch, and doc hygiene. Generic patterns are always
reported; TODO-type comments only when they carry leaky content. The
soft filter: a file that reads like an internal-facing document is
treated as one.

Large binaries: one configurable threshold, default 5 MB per tracked
file, with a hard flag above 50 MB. Tracked and untracked are
reported separately.

`.gitignore` findings: a present but unignored local artifact, and a
missing standard ignore for a detected carrier. Recommend resilient
directory and pattern ignores over direct file ignores.

A multi-round sensitive-information reference is built from known
risks, detected secrets and PII, and file-level judgments. It lives in
the gitignored directory, persists for reuse, is optional, and is
never included in the sanitized export. The scan stops when a round
adds nothing new.

### Licensing, attribution, authorship

Missing license is a decision prompt: recommend an explicit "all
rights reserved" notice or a chosen license. Flag declared-versus-actual
license mismatch, conflicting statements, invalid SPDX identifiers,
missing third-party notices, stripped headers in vendored files, and
missing credits or provenance. Flag only; do not author legal text.
Deeper compliance is a hand-off to a compliance workflow on request.

Authorship advice follows a user-defined preference: named attribution
or anonymity. When anonymity is wanted, recommend a project identity.

### Non-git projects

`gitleaks` scans a directory without git. The history carrier is
absent. Do not force `git init`.

### Known limits to name

Live verification; hosted services; non-English PII; very large repos;
archive and binary extraction; non-git history; Windows paths; and
submodule history (submodule contents and vendored code are scanned as
tree files, but a submodule's own history is not).

## Testing Decisions

Good tests exercise external behavior at the skill's seams, not script
internals. Two seams, one fixture.

**Fixture project.** A synthetic project with planted findings: a fake
secret in the working tree and one in git history, a PII string, an
image with EXIF, an Office document with an author field, a stray
artifact, a non-resilient `.gitignore` entry, and a tracked large
file. Write the expected-findings list before running anything.

**Seam A - script CLI (automated).** Invoke each deterministic helper
against the fixture and compare its output to the expected findings.
This covers inventory, history enumeration, `.gitignore` checking,
metadata scanning, and report rendering.

**Seam B - cold run (behavioral).** A fresh agent session runs the
procedure against the same fixture and is checked for intake, the soft
filter, severity assignment, the gating flow, and report shape.

**Gates:**

- **G1 hygiene** - no decision-tracking references in the artifact.
  Grep-able.
- **G2 cold run** - the fixture test passes.
- **G3 safety** - approval required, backup before rewrite, missing
  tool stops.

No neutrality pass.

## Out of Scope

- Code quality and architecture review.
- Doc-reality verification as an independent pass.
- CI configuration.
- General refactoring.
- Choosing a license for the user.
- Multi-repo handling. One run covers one project root.
- Multi-project and recurring-use config. Revisit post-v1.
- Naming and renames.
- Dependency vulnerability scanning.
- Post-publication drift.
- Pre-commit or CI hook integration.

## Further Notes

- Source: wayfinder map #12, decisions #13 through #24.
- Research: `docs/research/2026-09-29-secret-detection.md` and
  `docs/research/2026-09-29-pii-detection.md`.
- `gitleaks`, `presidio`, and `git-filter-repo` are not installed in
  the workstation variant today. Implementation must add them to the
  container or the workspace, and the skill must check for them at
  intake.
- The skill's own output directory must be excluded from the scan by
  exact path, always.
