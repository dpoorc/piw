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
secret in git history only, a PII string, an image with EXIF identity
and GPS tags, an Office document with an author field, a stray editor
artifact, a non-resilient `.gitignore` entry, a tracked large file, and
a file whose content contradicts its extension.

`expected.json` lists those findings. It is written before the fixture,
so a broken fixture fails loudly instead of passing every later check.

Both planted secret tokens are GitHub token shapes that the gitleaks
default rules detect. A sequential token shape is not detected, so the
fixture does not use one.

## Secrets scan

Seam A runs `scripts/secrets.py` against the fixture and checks that:

- a missing `gitleaks` stops the check with exit code 3 and a clear
  message;
- the scan runs and finds the working-tree secret and the history
  secret;
- every finding carries a confidence value.

It also runs `report.py` with the findings and checks that the report
carries the rotation hand-off. The check is skipped when `gitleaks` is
absent from the environment.

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
