# Secret detection research

Date: 2026-09-29
Status: Research complete
Supports: ticket #19 (Secrets detection approach), map #12

Research for the pre-publication sterilization skill. Scope: how an
agent-driven skill should detect secrets in the working tree and in
git history, and how it should control false positives.

Constraints the design must respect: procedure-first and
tool-assisted; no scanner may be assumed installed; works offline;
runs across text-like files and binaries; findings carry confidence
`certain`, `likely`, or `possible`.

All repository metadata below comes from the GitHub REST API on
2026-09-29. Rule counts and activity dates drift.

## 1. Scanner landscape

| Tool | Detection method | Git history | Offline | License | Activity |
|------|------------------|-------------|---------|---------|----------|
| gitleaks | regex + Shannon entropy + keyword prefilter + optional decoding | Yes (`git log -p`) | Yes | MIT | 2026-09-23, 29.5k stars |
| trufflehog | 700+ regex detectors + live API verification + entropy filter | Yes | With `--no-verification` | AGPL-3.0 | 2026-09-29, 28.2k stars |
| detect-secrets | regex plugins + entropy plugins + keyword detector + optional verification | No, by design | With `--no-verify` | Apache-2.0 | 2026-04-02, 4.6k stars |
| ggshield | 500-600+ GitGuardian detectors, server-side API | Repo scan, API-side | No, API key required | MIT | 2026-09-29, 2.0k stars |
| git-secrets | egrep regex from git config, optional AWS presets | Yes (`--scan-history`) | Yes | Apache-2.0 | 2025-09-17, 13.4k stars |
| Kingfisher | Vectorscan regex, Betterleaks/Veles rules, live validation | Yes | With `--no-validate` | Apache-2.0 | 2026-09-29, 1.2k stars |
| Titus | 487 Hyperscan rules, optional live validation | Yes (`--git`) | Yes by default | Apache-2.0 | active, replaces NoseyParker |
| NoseyParker | 188 precision-chosen regex rules | Yes | Yes | Apache-2.0 | retired |

## 2. Key findings

### gitleaks is regex-first with entropy as a per-rule threshold

- README: "Gitleaks is a tool for **detecting** secrets like
  passwords, API keys, and tokens in git repos, files, and whatever
  else you wanna throw at it via `stdin`."
- Default config: "Float representing the minimum shannon entropy a
  regex group must have to be considered a secret. entropy = 3.5".
- Keyword prefilter: "Keywords are used for pre-regex check
  filtering."
- The regex engine is RE2-like: "Golang's regex engine does not
  support lookaheads."
- The project is winding down: "Gitleaks is feature complete. I'm
  not merging new features into Gitleaks. Future releases will be
  security patches only. I'm shifting my focus to [Betterleaks]."

Do not pin rule updates to gitleaks alone.

### gitleaks scans history through patches, additions only

- "Under the hood, gitleaks uses the `git log -p` command to scan
  patches."
- "gitleaks only looks at additions in the git history."

A secret added and later removed can be missed. A working-tree scan
never sees history.

### trufflehog adds live verification and status classes

- "Verification eliminates false positives and provides three result
  statuses: **verified**, **unverified**, **unknown**."
- "We've added over 700 credential detectors that support active
  verification against their respective APIs."
- Verification is stateless by design. Provider APIs drift, so each
  detector needs maintenance.

### detect-secrets avoids history and is baseline-driven

- "It does this by running periodic diff outputs against
  heuristically crafted regex statements, to identify whether any
  *new* secret has been committed."
- Three strategies: regex rules, entropy detector, keyword detector.
- Entropy defaults: `--base64-limit` 4.5, `--hex-limit` 3.0.
- Documented limits: "**Things That Won't Be Prevented:** -
  Multi-line secrets - Default passwords that don't trigger the
  `KeywordDetector`".

A no-scanner helper must handle PEM blocks explicitly.

### ggshield is not usable offline

It sends content to a remote API and needs an API key.

### git-secrets is pure configured regex

It uses egrep patterns and a small AWS preset, and warns the
patterns "are **not** guaranteed to catch them **all**".

## 3. False-positive control

Four mechanisms recur across every mature scanner:

- **Allowlists and path filters.** gitleaks supports `[[rules.allowlists]]`
  and global allowlists with `commits`, `paths`, `regexes`,
  `stopwords`, and `condition = "OR"|"AND"`. Its default path
  allowlist excludes `node_modules`, lockfiles
  (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `go.sum`),
  `vendor/`, and minified vendor JS.
- **Baselines.** gitleaks: "When using a baseline, gitleaks will
  ignore any old findings that are present in the baseline."
  detect-secrets and Kingfisher offer baselines too.
- **Inline annotations.** `gitleaks:allow`, `.gitleaksignore`,
  `# pragma: allowlist secret`, `.gitallowed`, and
  `trufflehog:ignore`.
- **Verification as filter.** detect-secrets `--only-verified`;
  trufflehog `--results=verified` and `--filter-unverified`;
  Kingfisher `--only-valid`.

Additional heuristics in detect-secrets: `is_potential_uuid`,
`is_invalid_file`, wordlist and gibberish models, `--exclude-lines`,
`--exclude-files`, `--exclude-secrets`.

Newer tools trade precision differently. Betterleaks (MIT, by the
gitleaks author) filters on fragment attributes such as git author,
commit message, and file path, and uses BPE tokenization to measure
how non-human a string is. Kingfisher does checksum-aware offline
validation for some token types.

GitHub's own pattern documentation gives a usable precision
taxonomy: "Generic" regex patterns, "AI-detected" patterns, and
"Provider" regex patterns, with precision levels rated by typical
false-positive rate. It states that validity checks are not
supported for generic patterns.

## 4. No-scanner playbook

An agent with no scanner can reproduce most detection with three
primitives.

1. **Provider-prefixed regex sets.** The highest-precision rules are
   anchored literal prefixes. Examples from primary configs:
   - AWS: `AKIA|ASIA|ABIA|ACCA` + `[A-Z2-7]{16}`
   - GitHub: `ghp_|gho_|ghu_|ghs_|ghr_` + 36 chars, and
     `github_pat_\w{82}`
   - GCP: `AIza[\w-]{35}`
   - Slack and Vault prefixes
   - PEM headers: `-----BEGIN ... PRIVATE KEY-----`
2. **Shannon entropy as a secondary signal.** Observed thresholds:
   detect-secrets base64 4.5, hex 3.0; gitleaks `generic-api-key`
   3.5; trufflehog `--filter-entropy` starts at 3.0.
3. **Context signals.** Keyword prefilters such as `access`, `api`,
   `auth`, `key`, `password`, `secret`, `token`. detect-secrets
   cites research that a multi-factor secret often appears within
   five lines of context.

## 5. Git history enumeration without a scanner

- `git log -p` to scan patches.
- `git rev-list --objects --all` plus `git cat-file` to read objects.
- `git grep <pattern> $(git rev-list --all)` to search all
  revisions.

Remember: gitleaks-style patch scanning sees additions only.

## 6. Costs and limits

- **Large files.** gitleaks `--max-target-megabytes`; trufflehog
  `--archive-max-size`, `--archive-max-depth`, and
  `--archive-timeout`.
- **Binaries.** gitleaks skips archive traversal and decoding by
  default, and allowlists images, fonts, office documents, PDFs,
  and `.bin`, `.dll`, `.exe`, `.pdb`.
- **Generated and minified code.** Lockfiles, `node_modules`,
  `vendor/`, and minified vendor JS are allowlisted by default.

## 7. Live verification decision

Default it off.

- Benefit: removes false positives and reports active status.
- Cost: needs network, so it fails offline and returns `unknown`
  rather than `invalid`. It sends the secret to a third party.
  Providers rate-limit. Endpoints and key formats drift.
- Authorization: Kingfisher states that live validation "make[s]
  authorized requests to provider APIs" and must run "only where you
  are authorized to inspect the target account."

Enable it only when the user opts in and is authorized.

## 8. Confidence mapping (design proposal)

- **certain** - live-verified active credential, a private-key PEM
  block, or an exact known-format token with a valid checksum.
- **likely** - provider-prefixed regex plus keyword context plus
  entropy above threshold, unverified.
- **possible** - entropy-only match, a generic keyword assignment, or
  a provider pattern with no context.

Marked as a design proposal, not a source claim.

## 9. Licensing note

Bundling rule sets carries license terms:

- gitleaks rules - MIT, attribution required.
- detect-secrets rules - Apache-2.0.
- trufflehog detector code - AGPL-3.0. Do not bundle it.
- git-secrets rules and presets - Apache-2.0.

Regex patterns derived from MIT or Apache-2.0 projects are usable
with attribution.

## 10. Gaps

- No empirical false-positive rates. Only GitHub's qualitative
  precision ratings and vendor marketing claims.
- The 80 percent context figure comes from detect-secrets citing the
  NDSS 2019 paper, not the paper directly.
- No benchmark of regex or entropy pipelines on binary-heavy or
  minified repositories.
- No per-detector audit of which trufflehog verification calls are
  read-only.
- Activity dates come from `pushed_at` and may not reflect releases.
- gitleaks' additions-only behavior is a README note, not a formal
  spec.

## Sources

- https://github.com/gitleaks/gitleaks (README, `config/gitleaks.toml`)
- https://github.com/trufflesecurity/trufflehog (README)
- https://trufflesecurity.com/blog/how-trufflehog-verifies-secrets
- https://github.com/Yelp/detect-secrets (README, `docs/plugins.md`, `docs/filters.md`)
- https://github.com/GitGuardian/ggshield (README)
- https://docs.gitguardian.com/ggshield-docs/getting-started
- https://github.com/awslabs/git-secrets (README)
- https://github.com/betterleaks/betterleaks
- https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns
- https://git-scm.com/docs/git-rev-list
