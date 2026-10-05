---
name: pre-publication
description: >
  Sterilize a project before it becomes public. Inventory the project,
  scan for leak vectors (secrets, PII, metadata, doc and file hygiene,
  git history), produce a prioritized report, and apply approved fixes
  through per-action gates. Advisory-first. Use before open-sourcing,
  sharing with an outside party, or declassifying a project.
disable-model-invocation: true
---

# Pre-publication

Sterilize a project before it becomes public.

## Principles

- **Advisory-first.** The skill reports coverage and risk. It never
  certifies a project as safe.
- **No mutation without approval.** Every fix is proposed as an exact
  action first.
- **Inventory, do not classify.** Scan what is present. Do not assume
  a git repo, a build system, or a package manager.
- **Report before action.** Nothing changes until the report is
  presented and approved.

## Procedure

1. **Intake** - confirm the project root and the public mode, collect
   declared known risks and the authorship preference, check the
   tools, and prepare the output directory.
2. **Inventory** - list the content and meta layers that are present.
3. **Scan** - run content checks over text-like files and carrier
   checks where a carrier exists.
4. **Report** - write the prioritized report to the output directory.
5. **Gated fixes** - propose each fix, apply only what is approved,
   and gate destructive actions separately.

All stages are implemented: intake, inventory, the secrets, PII,
metadata, hygiene, and licensing vectors, the report, and the gated-fix
protocol.

## Stage 1: Intake

Do not scan before intake completes.

### 1. Project root

Take the project root from the invocation argument. Default to the
current directory. Confirm the directory exists.

### 2. Public mode

Ask what "public" means for this project:

- **open source** (default) - the project will be published openly.
- **shared** - the project goes to one outside party.
- **declassified** - internal material becomes releasable.

The mode sets the leak threshold.

### 3. Declared known risks

Ask whether the user already knows of anything in the project that
must not become public. Record each item verbatim. These become
declared known risks, and the report later marks each one found, not
found, or not checked.

Do not track exposure per finding. Declared known risks replace it.

### 4. Authorship preference

Ask whether the project wants named attribution or anonymity in
`AUTHORS`, `CONTRIBUTORS`, and source headers. Record the preference.
Do not assume.

### 5. Tool check

Run `scripts/tool_check.py`:

```
python3 scripts/tool_check.py --format text
```

Report the present and absent tools with install instructions. A
missing required tool stops its check. There is no weaker fallback.

Required tools: `gitleaks` (always), `exiftool` (when metadata
carriers exist), `git-filter-repo` (when a history rewrite is chosen),
`presidio` (for content PII).

Optional enhancers: `trufflehog` (invoke only, never bundle),
Kingfisher, or Titus.

Never install a tool automatically.

### 6. Output directory

Run `scripts/prepare_output.py`:

```
python3 scripts/prepare_output.py --project-root . --format text
```

It creates `.local/prepublish/` at the project root and reports whether
the path is gitignored. If the path is not ignored, propose adding the
single line `.local` to `.gitignore` as a gated fix. Do not edit
`.gitignore` here.

The output directory holds the report, the sanitized export, and the
sensitive-information reference. Exclude `.local/prepublish` from the
scan by exact path, always.

## Stage 2: Inventory

Run `scripts/inventory.py`:

```
python3 scripts/inventory.py --project-root . --format json > inventory.json
```

It lists the content categories present, the meta layers present, the
heavy directories it did not recurse into, and any extension or content
mismatch. A mismatch is a finding in its own right.

Carrier checks are gated by what the inventory shows. A check whose
carrier is absent is skipped, and the skip is recorded in the report.

## Stage 3: Scan

Run the vector checks. A content check runs over every text-like
file. A carrier check runs only when its carrier is present. See
`checks.md` for the per-vector detail.

### Secrets

`gitleaks` is required. Run `scripts/secrets_scan.py`:

```
python3 scripts/secrets_scan.py --project-root . --format text
```

It scans the working tree (`gitleaks dir`) and, when a git repository
is present, the git history (`gitleaks git`). It writes
`secrets.json` to the output directory.

If `gitleaks` is absent, the script exits 3 and records the skip. Do
not substitute a weaker scan.

Each finding carries class, carrier, location, severity, confidence,
and remediation kind. Secrets default to `critical` and
`rotate-credential`. The report's rotation hand-off lists the
affected credentials and the provider revocation location.

### PII

`presidio` is required for content PII. Run `scripts/pii.py`:

```
python3 scripts/pii.py --project-root . --format text
```

It scans text-like files with presidio and applies a bundled checksum
cross-check to cards, IBANs, and SSNs. An invalid checksum suppresses
the finding. It writes `pii.json` to the output directory.

If `presidio` is absent, the script exits 3 and records the skip. Do
not substitute a weaker scan.

Metadata PII (EXIF, GPS, and document properties) belongs to the
metadata vector.

### Metadata

`exiftool` is required when the inventory holds image, office, or PDF
carriers. Run `scripts/metadata.py scan`:

```
python3 scripts/metadata.py scan --project-root . --format text
```

It reads file metadata with exiftool, checks the repository metadata
with git, and collects the commit identities. It writes `metadata.json`
to the output directory. If exiftool is absent while carriers exist,
the file-metadata check is recorded as skipped and the git checks still
run. There is no weaker fallback for file metadata.

The report lists the three commit identity options: a project identity
for future commits, a history rewrite for the past, and `.mailmap` for
display only.

Removal is a separate, gated step. It selects the identity and location
tags by default and keeps functional tags such as `Orientation`:

```
python3 scripts/metadata.py remove photo.jpg \
  --confirm-destructive --backup photo.jpg.bak
python3 scripts/metadata.py remove photo.jpg --out photo.clean.jpg
```

`--strip-all` is opt-in and warns that it drops functional tags.
In-place removal is destructive under the gate. The script re-reads the
file to confirm the tags are gone. exiftool cannot write OOXML; for an
OOXML file the script rewrites the identity parts with the standard
library `zipfile` module.

### Hygiene

Run `scripts/hygiene.py`:

```
python3 scripts/hygiene.py --project-root . --format text
```

It finds strays, large files, internal references, leaky TODO-type
comments, internal-facing documents, `.gitignore` gaps, and extension
and content mismatch. It writes `hygiene.json` to the output directory.

The large-file threshold is 5 MB by default (`--large-mb`) with a 50 MB
hard flag (`--hard-mb`). Tracked and untracked files are reported
separately. A TODO, FIXME, or HACK comment is reported only when the
line carries leaky content. `.gitignore` findings suggest a resilient
directory or pattern ignore.

### Licensing, attribution, and authorship

Run `scripts/licensing.py`:

```
python3 scripts/licensing.py --project-root . --format text \
  --authorship ask
```

It checks license presence and consistency, third-party notices and
attribution, and the authorship preference. It writes `licensing.json`
to the output directory.

A missing license is a decision, not a defect: it is `medium` and the
report prompts for a chosen license or an explicit all-rights-reserved
notice. A declared-versus-actual mismatch and a conflicting statement
are `high`.

The `--authorship` preference is `ask`, `named`, or `anonymous`. With
`ask`, the report prompts for the preference. With `anonymous`, a
personal name in an authorship artifact is `medium`. With `named`, no
authorship finding is emitted.

The check is high-level. It does not select a license, audit dependency
compatibility, or author legal text. A deeper audit is a hand-off to a
compliance workflow.

## Stage 4: Report

Run `scripts/report.py`:

```
python3 scripts/report.py --project-root . \
  --public-mode "open source" \
  --known-risk "..." \
  --inventory inventory.json \
  --tools tools.json \
  --findings .local/prepublish/secrets.json \
  --findings .local/prepublish/pii.json \
  --findings .local/prepublish/metadata.json \
  --findings .local/prepublish/hygiene.json \
  --findings .local/prepublish/licensing.json \
  --sanitize \
  --stage intake --stage inventory --stage scan
```

It writes `report.md` to the output directory. With `--sanitize` it also
writes `report.sanitized.md`, which strips values, rules, and tags, drops
the advice section and the project root, and is safe to share. The full
report has header, declared known risks, findings, skipped checks,
suggested remediation plan, advice, non-findings, and readiness summary.
Each declared known risk is marked
found, not found, or not checked.

## Stage 5: Gated fixes

Nothing is applied without approval. The ledger records every proposed
fix and its state.

```
python3 scripts/fixes.py --project-root . add --from proposals.json
python3 scripts/fixes.py --project-root . list
python3 scripts/fixes.py --project-root . approve F1
python3 scripts/fixes.py --project-root . apply F1
python3 scripts/fixes.py --project-root . verify F1
```

Rules the script enforces:

- A fix is applied only after it is approved.
- A batch approval covers low-risk reversible fixes only. Every other
  fix is approved on its own.
- A destructive fix needs a separate confirmation, a named backup that
  exists, and a recorded restore command. The restore command is
  printed on apply.
- A credential rotation is handed off. A history rewrite is never a
  substitute for rotation.

After a destructive fix, offer to run the project's smoke test or test
suite. Align with the user before you run it. When the user confirms the
result, offer to remove the backup.

Propose the exact action, not a description of the action. Name the
file, the line, and the command.

### History rewrite

A rewrite is separate from the fix ledger. It owns its backup and its
confirmation:

```
python3 scripts/rewrite.py plan --project-root . \
  --path config/credentials.py
python3 scripts/rewrite.py run --project-root . \
  --path config/credentials.py --confirm-destructive
python3 scripts/rewrite.py verify --project-root . \
  --path config/credentials.py
```

Use `--replace "literal"` instead of `--path` to replace a secret
string that is still in the tree. `run` takes a backup ref and a
verified `git bundle`, prints the restore command, rewrites the local
refs, removes the `origin` remote, expires the reflog, and garbage
collects. It never pushes. `verify` confirms the target is gone from the rewritten refs.
The backup ref and the bundle keep the old history on purpose; delete
them when the user no longer needs the backup. A rewrite is never a
substitute for rotation.

## Invocation

Optional arguments:

- project root (default: current directory);
- public mode (default: open source).

## Known limits

- Live verification, hosted services, and non-English PII are not
  covered.
- Archive and binary extraction is covered only by the optional
  enhancers.
- Submodule contents are scanned as tree files; a submodule's own
  history is not scanned.
- Windows paths and very large repos are not exercised.
