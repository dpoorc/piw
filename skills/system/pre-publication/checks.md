# Pre-publication check reference

Per-vector detail for the scan stage. Load the section you need. The
procedure is in `SKILL.md`.

## Secrets

Tool: `gitleaks`. Required. No fallback.

### What runs

`scripts/secrets.py` runs two scans:

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
