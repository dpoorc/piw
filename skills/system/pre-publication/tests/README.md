# Pre-publication tests

Two seams verify the skill. One fixture serves both.

## Seam A: automated

Run:

```
python3 tests/run_seam_a.py
```

Seam A builds the fixture, proves every planted finding is present,
runs the scripts, and checks the output. It exits non-zero on failure.
Use `--target DIR` to build the fixture at a known path and keep it for
inspection.

A failure means the fixture or a script is wrong. It does not mean a
project is clean.

## Seam B: behavioural

Seam B is a cold agent run. Start an agent with only `SKILL.md`, point
it at the fixture, and observe whether it follows the intake, reports
before acting, and holds the gates. Seam B is run by hand. It is not
automated, because the point is the agent's behaviour, not its output
bytes.

Build the fixture first, then hand the path to the agent:

```
python3 tests/make_fixture.py --target /tmp/prepublish-fixture
```

## The fixture

`make_fixture.py` builds a synthetic project in a temporary directory.
Nothing is committed from it. It plants a secret in the working tree, a
secret in git history only, a PII string, an image with EXIF identity,
GPS, and orientation tags, an Office document with an author field, a
remote URL with an embedded credential, a stray editor artifact, a
non-resilient `.gitignore` entry, a tracked large file, and a file whose
content contradicts its extension.

`expected.json` lists those findings. It is written before the fixture,
so a broken fixture fails loudly instead of passing every later check.

Both planted secret tokens are GitHub token shapes that the gitleaks
default rules detect. Each token has enough entropy to pass the rule.

## Secrets scan

Seam A runs `scripts/secrets_scan.py` against the fixture and checks that:

- a missing `gitleaks` stops the check with exit code 3 and a clear
  message;
- the scan runs and finds the working-tree secret and the history
  secret;
- every finding carries a confidence value.

It also runs `report.py` with the findings and checks that the report
carries the rotation hand-off. The check is skipped when `gitleaks` is
absent from the environment.

## PII scan

Seam A runs `scripts/pii.py` against the fixture and checks that:

- a missing `presidio` stops the check with exit code 3 and a clear
  message;
- the scan finds the fixture email and phone number;
- every finding carries a confidence value.

It also checks that the report carries the PII findings. The check is
skipped when `presidio` is absent. To run it, use an interpreter where
`presidio_analyzer` is importable.

## Metadata scan

Seam A runs `scripts/metadata.py scan` against the fixture and checks
that:

- a missing `exiftool` records the file-metadata check as skipped, and
  the git checks still run;
- the scan finds the EXIF identity and GPS tags, the Office author
  field, and the remote credential;
- the commit identity options are presented;
- selective removal keeps `Orientation` and removes `Artist` and GPS;
- OOXML removal removes the author field;
- an in-place removal is refused without `--confirm-destructive`;
- an in-place removal is refused without `--backup`.

The scan check is skipped when `exiftool` is absent. The removal checks
need `exiftool` for the image and only the standard library for the
Office document.

## Hygiene scan

Seam A runs `scripts/hygiene.py` against the fixture and checks that:

- the scan runs and finds the stray artifact, the non-resilient ignore
  entry with a suggestion, the tracked large file, the extension
  mismatch, and the internal-facing document;
- an untracked large file is `medium`, and the threshold is
  configurable;
- a generic TODO comment is not reported, and a leaky one is.

It also checks that the report carries the protection additions.

## Licensing scan

Seam A runs `scripts/licensing.py` against the fixture and checks that:

- the scan runs and finds the declared-versus-actual mismatch at `high`;
- the vendored directory with no notice is found;
- the licensing scope and authorship preference are presented;
- `--authorship named` emits no authorship finding, and
  `--authorship anonymous` flags the `AUTHORS` file;
- a missing license is a `medium` decision with `add-protection`.

It also checks that the report carries the licensing advice.

## Gate G1

`g1_hygiene.py` fails if the shipped skill carries planning residue:
ticket numbers, batch names, option letters, or TODO markers. The test
harness is excluded from the gate.

## The gate scenario

Seam A drives the fix ledger through a full scenario: propose, refuse
to apply without approval, refuse to batch a destructive fix, apply a
destructive fix only with a backup and a printed restore command, and
verify only an applied fix.

## Later vectors

As each vector lands, add its assertion to Seam A. The fixture already
holds the input.
