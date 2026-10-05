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
URLs, stashes, notes, annotated tags, custom hooks, and a changed
`.git/description`.

Commit identity: the distinct author and committer identities in
history. The report lists the three options: a project identity for
future commits, a history rewrite for the past, and `.mailmap` for
display only.

### Severity and remediation

A credential in a remote URL is `critical` with `rotate-credential`. A
credential helper, a local path in config, or a stash is `medium`. An
identity or location tag is `high`. Device tags are `medium`. Tags,
notes, hooks, and a changed description are `low`. File metadata uses
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
