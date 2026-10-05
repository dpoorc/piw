# Pre-publication check reference

Per-vector detail for the scan stage. Load the section you need. The
procedure is in `SKILL.md`.

## Secrets

Tool: `gitleaks`. Required. No fallback.

### What runs

`scripts/secrets_scan.py` runs two scans:

- `gitleaks dir` over the working tree.
- `gitleaks git` over the git history, when a `.git` directory exists.

It writes `secrets.json` to the output directory. It excludes
`.local/prepublish` by exact path with a generated gitleaks config that
extends the default rules.

### Detection

The skill uses the gitleaks default rule set. It does not carry its own
secret patterns. Detection combines an anchored provider prefix, a
Shannon entropy threshold, and a keyword prefilter. This is the layered
approach that the mature scanners converge on.

### Confidence

Each finding carries one value:

- `certain` - a private-key PEM block, or a checksum-valid token.
- `likely` - a provider-prefixed rule with entropy above threshold.
- `possible` - a generic rule, or a provider rule with no context.

Live verification stays off. It needs network and authorization, and it
sends the secret to a third party. A verified credential would be
`certain`; without verification, a provider rule is `likely`.

### Severity and remediation

The class default is `critical`. The taxonomy reserves `critical` for a
live secret and `high` for a revoked one. Offline detection cannot tell
them apart, so the default is the worst case, and the user overrides it
per finding.

The remediation kind is `rotate-credential`. Rotation closes the leak.
The carrier sets the rest of the order: a working-tree secret needs a
forward fix, and a history secret needs a history rewrite.

### Rotation hand-off

The report lists each affected credential, the provider revocation
location, and the confirmation step. Publication stays blocked until
the user confirms each rotation. A history rewrite is never a
substitute for rotation.

### False-positive controls

- Provider-prefixed rules rank above generic rules, and confidence
  records the difference.
- The default gitleaks path allowlist excludes `node_modules`,
  lockfiles, `vendor/`, and minified vendor JS.
- The output directory is excluded by exact path.
- The user dismisses a finding by confidence, without a second pass.

### Limits

- History scanning reads patch additions. A secret that appears only in
  a non-addition context is not seen.
- A secret added before the scanned range is not seen.
- Archives and binaries are not traversed. The optional `trufflehog`
  enhancer covers them.
- Live verification is off by default.

## PII

Tool: `presidio`. Required for content PII. No fallback.

### What runs

`scripts/pii.py` walks the text-like files and runs presidio over each
one. It applies a bundled checksum cross-check to the structured
identifiers. It writes `pii.json` to the output directory.

Metadata PII is out of scope. The metadata vector owns EXIF, GPS, and
document properties.

### Detection

PII is defined by identifiability, not by a fixed list. Detection does
not hardcode one legal regime. It combines three signals: a checksum or
structural check, a pattern match, and context. Names and postal
addresses come from presidio's NER model.

The scan asks for a fixed entity set. `URL` and `DATE_TIME` are left
out, because they are not personal data on their own.

### Confidence

Each finding carries one value:

- `certain` - a checksum-valid card number or IBAN.
- `likely` - an email, a phone number, a person name, a location, or a
  structurally valid SSN.
- `possible` - a low-precision recognizer such as NRP, or a low NER
  score.

An invalid checksum suppresses the finding. A card number that fails
Luhn, an IBAN that fails MOD-97, and an SSN with an invalid area, group,
or serial are not reported.

### Severity and remediation

The severity follows the entity: SSN and medical data are `critical`,
names, passports, licenses, and financial data are `high`, contact and
online identifiers are `medium`. The remediation kind is `forward-fix`:
redact or remove the value. A value already committed also needs a
history rewrite, which the git history vector owns.

### False-positive controls

- Checksum validation suppresses invalid structured values.
- NER entities are `likely`, not `certain`. NRP is `possible`.
- The scan reports the score for each finding.
- The user dismisses a finding by confidence, without a second pass.

### Limits

- Non-English PII is not covered. The scan runs the English model.
- A file larger than 2 MB is skipped.
- NER has false positives. A name in ordinary prose is reported at
  `likely`.
- Metadata PII is deferred to the metadata vector.

## Metadata

Tool: `exiftool`. Required when the inventory holds image, office, or
PDF carriers. Git is used for the repository metadata. No weaker
fallback for file metadata.

### What runs

`scripts/metadata.py scan` reads file metadata with exiftool, checks the
repository metadata with git, and collects the commit identities. It
writes `metadata.json` to the output directory.

### Detection

File metadata: exiftool reads every image, office, and PDF carrier. The
scan matches identity and location tags: `Artist`, `OwnerName`,
`SerialNumber`, `Creator`, `LastModifiedBy`, `Author`, `By-line`,
`Credit`, `Source`, `Company`, `Manager`, `Make`, `Model`, `Software`,
`CreatorTool`, and every `GPS*` tag. Copyright and licensor fields
belong to the licensing vector.

Repository metadata: remote URLs with an embedded credential,
`credential.helper`, config values with an absolute path, `.gitmodules`
URLs, stashes, notes, annotated tags, the reflog, custom hooks and their
contents, and a changed `.git/description`.

Commit identity: the distinct author and committer identities in
history. The report lists the three options: a project identity for
future commits, a history rewrite for the past, and `.mailmap` for
display only.

### Severity and remediation

A credential in a remote URL is `critical`. A credential in a custom
hook is `medium`. Both use `rotate-credential`. A credential helper, a
local path in config, or a stash is `medium`. An identity or location
tag is `high`. Device tags are `medium`. Tags, notes, the reflog, a
custom hook, and a changed description are `low`. File metadata uses
`forward-fix`. Annotated tags use `history-rewrite`.

### Removal

`scripts/metadata.py remove` selects the identity and location tags by
default. It keeps functional tags, including `Orientation`, the color
profile, and dimensions. `--strip-all` is opt-in and warns that it
drops functional tags. An in-place edit is destructive and needs
`--confirm-destructive`. An out-of-place write with `--out` is not
destructive. The script re-reads the file to confirm the tags are gone.

exiftool cannot write OOXML. For OOXML the script rewrites
`docProps/core.xml`, `docProps/app.xml`, and `docProps/custom.xml` with
the standard library `zipfile` module. It preserves the entry order and
the entry metadata, and replaces the file atomically.

### False-positive controls

- A tag is reported only when exiftool reads it from the file.
- The remote check flags a userinfo field with a colon, not a bare
  username such as `git@host`.
- The value in the report is masked: the password becomes `***`.

### Limits

- exiftool is the only file reader. There is no fallback.
- PDF removal is offered through exiftool; OOXML removal uses
  `zipfile`. Other formats are report-only.
- The scan reads metadata; it does not prove that no metadata remains.
- Commit identity rewriting belongs to the git history vector.

## Hygiene

Tool: none required. Git is used when the project is a repository.

### What runs

`scripts/hygiene.py` walks the working tree and the git metadata. It
writes `hygiene.json` to the output directory. The check list is
open-ended, not exhaustive.

### Detection

- Strays: editor and OS artifacts, backup and swap files, editor lock
  files, logs, crash dumps, local databases, editor and scratch
  directories. An empty file and a broken symlink are low findings.
- Large files: one threshold, default 5 MB per file, with a hard flag
  above 50 MB. Tracked and untracked files are reported separately. A
  tracked large file is a repository problem. An untracked one is only
  an export problem.
- Internal references: an absolute home path, a private URL
  (`localhost`, a loopback or private address), an internal host
  (`.internal`, `.corp`, `.lan`, `.intranet`, `.local`), and an internal
  ticket link.
- Leaky comments: a `TODO`, `FIXME`, or `HACK` comment is reported only
  when the line also carries a leaky marker: a private link, an email,
  a home path, a ticket ID, or internal or confidential language. A
  generic TODO is not a finding.
- Internal-facing documents: the soft filter. A file whose path or
  content reads as internal is treated as one.
- `.gitignore` gaps: a direct file entry that is not resilient, a
  present local artifact that is not ignored, and a missing standard
  ignore for a detected carrier.
- Extension and content mismatch, from the inventory.

### Severity and remediation

A tracked large file, an internal-facing document, an internal host, and
an internal ticket link are `high`. A private URL, an absolute home
path, an ignore gap, a leaky comment, and an extension mismatch are
`medium`. A stray is `low`, except a local database, which is `medium`.

Remediation is `forward-fix` for a stray, a large file, a leaky
comment, and a mismatch. It is `history-rewrite` for a tracked large
file. It is `add-protection` for an ignore gap.

### False-positive controls

- TODO-type comments need a leaky marker. A bare TODO is not reported.
- A binary file with no known signature is not an extension mismatch.
- The internal-document filter is soft and reports its reason.
- Ignore suggestions prefer a directory or a pattern over a file path.

### Limits

- The check list is open-ended. A clean run is not proof of hygiene.
- Specific codenames and ticket prefixes come from a project-supplied
  list, not from guesswork.
- Personal names in comments are left to the PII vector.
- File-system metadata stays with the metadata vector.
- Doc-reality checking stays with the `verify-docs` skill.

## Licensing, attribution, and authorship

Tool: none. The check is high-level and read-only.

### What runs

`scripts/licensing.py` checks license presence and consistency,
third-party notices and attribution, and the authorship preference. It
writes `licensing.json` to the output directory.

### Detection

- License presence: a license file at the project root.
- Consistency: the license named in a README or a manifest against the
  license file text. The license file is identified by its text, such as
  `Apache License, Version 2.0` or `Permission is hereby granted, free
  of charge`. Two files that declare different licenses are a conflict.
- SPDX: an `SPDX-License-Identifier` line. A malformed identifier is
  `medium`. An unrecognized but well-formed identifier is `low`, with a
  prompt to verify.
- Attribution: a vendored directory (`vendor`, `third_party`, `deps`,
  and others) with no license or notice beside it. An Apache-2.0 license
  with no `NOTICE` file.
- Authorship: with `--authorship anonymous`, a personal name in
  `AUTHORS`, `CONTRIBUTORS`, `CREDITS`, `MAINTAINERS`, or a manifest
  author field.

### Severity and remediation

A declared-versus-actual mismatch, a conflicting statement, and a
missing third-party notice are `high`. A missing license and a personal
name when anonymity is wanted are `medium`. A cosmetic SPDX issue is
`low`.

Remediation is `forward-fix` (correct or redact) or `add-protection`
(add a `LICENSE` or `NOTICE`). It is never automatic.

### False-positive controls

- A missing license is framed as a decision, not a defect.
- A dual declaration such as `MIT OR Apache-2.0` is not a mismatch when
  the actual license is one of the declared set.
- An unrecognized SPDX identifier is `low` with a verify prompt, not an
  error.
- The authorship preference is asked, not assumed.

### Limits

- The skill flags only. It does not select a license, audit dependency
  compatibility, or author legal text.
- Deeper compliance is a hand-off to a compliance workflow, on request.
- Contribution policy (DCO, CLA) is out of scope.
- License selection and naming stay out of scope.
- The license fingerprints cover the common licenses, not every license.
