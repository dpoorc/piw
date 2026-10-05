---
id: 49
title: pre-publication skill design — wayfinder map
status: closed
priority: high
labels:
    - wayfinder:map
created: "2026-09-29"
updated: "2026-10-05"
closed: "2026-10-05"
---

**Status:** map clear as of 2026-10-01. All 12 tickets closed. The way
to the destination is clear. Handed off to `to-spec`.

## Destination

A generic `pre-publication` skill that sterilizes a project before it
becomes public. It inventories the project's content and meta layers,
scans for leak vectors (secrets, PII, metadata, doc and file hygiene,
git history where present), produces a prioritized report, and applies
approved fixes through per-action gates. Advisory-first, adaptive to
what the inventory shows, and bounded to leak prevention.

## Notes

**Skills to consult per session:** grilling, domain-modeling,
research, prototype, ste-writing, writing-for-agents, verify-docs

**Domain:** Leak prevention at the moment a project crosses from
private to public. "Public" includes open source, shared with an
outside party, or declassified. Code projects are the primary focus.
Non-code publishing gets generic guidance only.

**Standing preferences:**
- Advisory-first. Every mutation needs explicit, per-action approval.
- Treat git history work as irreversible. Never rewrite without a
  stated backup and a credential-rotation plan.
- Adapt to project type. Do not assume a git repo, a build system,
  or a package manager.
- Non-code publishing is one section, not a workstream.
- Keep ticket bodies free of real secrets. This map is public with
  the piw repo.

**Scope guard (anti-creep):**
- Map capped at about 12 decision tickets. Cut scope, do not extend
  the map.
- No separate contracts document. Each decision lives in its ticket.
- Prototype only when a decision needs a concrete artifact.
- Research only for facts genuinely outside this repo.
- Non-goals: code quality, CI setup, general refactoring, and
  doc-writing overhaul.

## Decisions so far

- [Skill boundary and non-goals](.issues/0050-skill-boundary-and-non-goals.md) - Procedure-first and tool-assisted, one project root per run, "public" is an input, licensing and attribution in narrowly, supply-chain scanning out, and the non-goals list fixed.
- [Leak-vector taxonomy and severity model](.issues/0051-leak-vector-taxonomy-and-severity-model.md) - Class-by-carrier matrix, six vector classes, four severity tiers, a separate remediation kind, per-finding confidence, and declared known risks instead of exposure tracking. History edits are judgement calls.
- [Project classification and adaptation model](.issues/0052-project-classification-and-adaptation-mo.md) - No kind taxonomy. The skill inventories present content and meta layers, gates checks by carrier, runs content checks over all text-like files, verifies content against extensions, and records skipped checks. An extension or content mismatch is itself a flag.
- [Secrets detection approach](.issues/0056-secrets-detection-approach.md) - Layered detection (prefixed regex, entropy, context), both tree and history, four false-positive controls, live verification off by default. Findings in [research/2026-09-29-secret-detection.md](docs/research/2026-09-29-secret-detection.md).
- [PII detection approach](.issues/0057-pii-detection-approach.md) - Identifiability-based definition, checksum plus pattern plus context, regime-neutral, NER required for names and addresses, metadata channels included. Findings in [research/2026-09-29-pii-detection.md](docs/research/2026-09-29-pii-detection.md).
- [Report format and gated-fix protocol](.issues/0053-report-format-and-gated-fix-protocol.md) - Report in gitignored `./.local/prepublish/` (excluded from the scan), six sections, unsanitized by default with an optional sanitized export, exact fix proposals, separate gate and backup for irreversible actions, readiness summary instead of a verdict. Tracked status sets remediation and ordering, not severity.
- [Git history handling](.issues/0054-git-history-handling.md) - Requires `git-filter-repo` with no fallbacks. Rewrite is user-approved and never replaces rotation. Backup ref plus `git bundle` before any rewrite, never push, warn about forks and host caches, expire reflog and gc, then re-scan to confirm.
- [Metadata hygiene](.issues/0055-metadata-hygiene.md) - `exiftool` primary for media, Office, and PDF. Selective removal of identity and location tags, keep functional tags and orientation, destructive gate for in-place edits. Commit identity via config, rewrite, or mailmap. Repository metadata checklist including credentials embedded in remote URLs. `#58` owns file content, in history or not.
- [Doc and file hygiene](.issues/0058-doc-and-file-hygiene.md) - Open-ended check list (strays, large binaries, internal references, leaky TODOs, `.gitignore` gaps, extension mismatch, doc hygiene). Soft "reads like an internal document" filter plus a multi-round sensitive-information reference in `.local/prepublish/`. Resilient ignore patterns. Full four-tier severity.
- [Ancillary vectors: licensing, attribution, authorship](.issues/0059-ancillary-vectors-licensing-attribution.md) - Missing license is a decision prompt (add "all rights reserved" or choose). License consistency and third-party notices flagged at a high level; deeper compliance is a hand-off to a compliance workflow. Authorship advice is user-defined (named attribution vs anonymity); `#55` owns the mechanics. Naming out.
- [Packaging and invocation](.issues/0060-packaging-and-invocation.md) - Name `pre-publication`, user-invoked, at `skills/system/pre-publication/`. `SKILL.md` plus `checks.md` plus Python 3 stdlib-only `scripts/`. Required tools: `gitleaks`, `exiftool`, `git-filter-repo`, `presidio`. Optional enhancers from the inventory: `trufflehog` or Kingfisher/Titus. No weaker fallback. Supersedes the no-scanner stance in #50, #56, and #57.
- [Good-enough bar and verification](.issues/0061-good-enough-bar-and-verification.md) - Six v1 criteria, a fixture project with planted findings for verification, three gates (hygiene, cold run, safety), named known limits, and a hand-off to `to-spec` then `to-tickets` then `implement`.

## Not yet specified (fog)

None. Every fog item was resolved or ruled out of scope:

- Multi-project and recurring-use config - out of scope for v1.
- Submodules and vendored code - resolved in `#61`.
- Post-publication drift - out of scope.
- Non-code publishing depth - resolved by `#50` and `#58`.
- Pre-commit or CI hook integration - out of scope.

## Out of scope

- Code quality and architecture review - handled by `code-review`.
- Doc-reality verification as an independent pass - handled by
  `verify-docs`. The skill may invoke it, but does not own it.
- CI configuration.
- General refactoring.
- Choosing a license for the user. The skill advises on
  leak-relevant attribution, not on license selection.
- Multi-repo handling. One run covers one project root. A monorepo
  counts as one project.
- Naming and renames. A rename is not leak prevention.
- Dependency vulnerability scanning. That is a security audit, not
  leak prevention.
- Multi-project and recurring-use config. One run covers one project
  root. Revisit post-v1.
- Post-publication drift. The skill runs before publication, not
  after.
- Pre-commit or CI hook integration. The skill is a deliberate one-off
  pass, not a gate.
