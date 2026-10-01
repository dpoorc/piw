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

Intake, inventory, the report skeleton, and the gated-fix protocol are
implemented. The scan stages arrive with their own work.

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

## Stage 4: Report

Run `scripts/report.py`:

```
python3 scripts/report.py --project-root . \
  --public-mode "open source" \
  --known-risk "..." \
  --inventory inventory.json \
  --tools tools.json \
  --stage intake --stage inventory
```

It writes `report.md` to the output directory. The sections are header,
declared known risks, findings, skipped checks, suggested remediation
plan, non-findings, and readiness summary.

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

Propose the exact action, not a description of the action. Name the
file, the line, and the command.

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
